pragma solidity >=0.4.25 <0.6.0;

contract SupplyChain {

    address public Owner;
    
    constructor () public {
        Owner = msg.sender;
    }
/********************************************** Owner Section *********************************************/
    modifier onlyOwner() {
        require(
            msg.sender == Owner,
            "Only owner can call this function."
        );
        _;
    }

    // modifier onlySupplier() {
    //     require(
    //         UsersDetails[msg.sender].role == roles(1),
    //         "Only Supplier can call this function."
    //     );
    //     _;
    // }

    // modifier onlyTransporter() {
    //     require(
    //         UsersDetails[msg.sender].role == roles(1),
    //         "Only Transporter can call this function."
    //     );
    //     _;
    // }
    // modifier onlyManufacturer() {
    //     require(
    //         UsersDetails[msg.sender].role == roles(1),
    //         "Only Manufacturer can call this function."
    //     );
    //     _;
    // }
    // modifier onlyWholesaler() {
    //     require(
    //         UsersDetails[msg.sender].role == roles(1),
    //         "Only Wholesaler can call this function."
    //     );
    //     _;
    // }

    enum roles {norole, supplier, transporter, manufacturer, wholesaler, distributer, pharma, revoke }
    
    event UserRegister(address indexed EthAddress, bytes32 Name);
    event UserRoleRevoked(address indexed EthAddress, bytes32 Name, uint Role);
    event UserRoleRessigne(address indexed EthAddress, bytes32 Name, uint Role);
    
    function registerUser(
        address EthAddress, 
        bytes32 Name, 
        bytes32 Location, 
        uint Role
        ) public 
        onlyOwner 
        {
        require(UsersDetails[EthAddress].role == roles.norole, "User Already registered");
        UsersDetails[EthAddress].name = Name;
        UsersDetails[EthAddress].location = Location;
        UsersDetails[EthAddress].ethAddress = EthAddress;
        UsersDetails[EthAddress].role = roles(Role);
        users.push(EthAddress);
        emit UserRegister(EthAddress, Name);
    }
    function revokeRole(address userAddress) public onlyOwner {
        require(UsersDetails[userAddress].role != roles.norole, "User not registered");
        emit UserRoleRevoked(userAddress, UsersDetails[userAddress].name,uint(UsersDetails[userAddress].role));
        UsersDetails[userAddress].role = roles(7);
    }
    function reassigneRole(address userAddress, uint Role) public onlyOwner {
        require(UsersDetails[userAddress].role != roles.norole, "User not registered");
        UsersDetails[userAddress].role = roles(Role);
        emit UserRoleRessigne(userAddress, UsersDetails[userAddress].name,uint(UsersDetails[userAddress].role));
    }
/********************************************** User Section **********************************************/
    struct UserInfo {
        bytes32 name;
        bytes32 location;
        address ethAddress;
        roles role;
    }

    mapping(address => UserInfo) UsersDetails;
    address[] users;

    function getUserInfo(address User) public view returns(
        bytes32 name,
        bytes32 location,
        address ethAddress,
        roles role
        ) {
        return (
            UsersDetails[User].name,
            UsersDetails[User].location,
            UsersDetails[User].ethAddress,
            UsersDetails[User].role);
    }

    function getUsersCount() public view returns(uint count){
        return users.length;
    }

    function getUserbyIndex(uint index) public view returns(
        bytes32 name,
        bytes32 location,
        address ethAddress,
        roles role
        ) {
        return getUserInfo(users[index]);    
    }
/********************************************** Supplier Section ******************************************/
    mapping(address => address[]) supplierRawProductInfo;
    event RawSupplyInit(
        address indexed ProductID, 
        address indexed Supplier, 
        address Shipper, 
        address indexed Receiver
    );
    function createRawPackage(
        bytes32 Des,
        bytes32 FN, 
        bytes32 Loc, 
        uint Quant, 
        address Shpr, 
        address Rcvr
        ) public {
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        RawMatrials rawData = new RawMatrials(
            msg.sender,
            Des,
            FN,
            Loc,
            Quant,
            Shpr,
            Rcvr
            );
        supplierRawProductInfo[msg.sender].push(address(rawData));
        emit RawSupplyInit(address(rawData), msg.sender, Shpr, Rcvr);
    }

    function getCountOfProducts() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender].length;
    }

    function getProductIdByIndex(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender][index];
    }

/********************************************** Transporter Section ******************************************/
    
    function loadpacakage(
        address pid, 
        uint transportertype,
        address cid
        // uint receivertype
        ) public {
            require(
                UsersDetails[msg.sender].role == roles.transporter,
                "Only Transporter can call this function"
            );
            require(
                transportertype > 0,
                "Transporter Type must be define"
            );
        if(transportertype == 1) {  // Supplier to Manufacturer
            RawMatrials(pid).pickPackage(msg.sender);
        } else if(transportertype == 2) {   // Manufacturer to Wholesaler OR Manufacturer to Distributer
            Madicine(pid).pickPackage(msg.sender);
            // require(
        //         msg.sender == madicineBatchDetails[pid].shipper,
        //         "Transporter is other user"
        //     );
        //     require(receivertype != 0,"Receiver Type must be define");
        //     madicineBatchDetails[pid].status = madicineStatus(receivertype);
            // if(receivertype == 1){
        //         emit ShippmentUpdate(pid, msg.sender, madicineBatchDetails[pid].wholesaler,2,1);
        //     } else if(receivertype == 2){
        //         emit ShippmentUpdate(pid, msg.sender, madicineBatchDetails[pid].manufacturer,2,2);
        //     }
        } else if(transportertype == 3) {   // Wholesaler to Distributer
            MadicineW_D(cid).pickWD(pid,msg.sender);
        //     require(
        //         msg.sender == madicineWtoD[pid].shipper,
        //         "Transporter is other user"
        //     );
        //     madicineWtoD[pid].status = packageStatus(1);
        //     emit ShippmentUpdate(pid, msg.sender, madicineWtoD[pid].receiver,1,1);
        } else if(transportertype == 4) {   // Distrubuter to Pharma
            MadicineD_P(cid).pickDP(pid,msg.sender);
        //     require(
        //         msg.sender == madicineDtoR[pid].shipper,
        //         "Transporter is other user"
        //     );
        //     madicineDtoR[pid].status = packageStatus(1);
        //     madicineBatchDetails[pid].status = madicineStatus(5);
            // emit ShippmentUpdate(pid, msg.sender, madicineDtoR[pid].receiver,1,1);
        }
    }

/********************************************** Manufacturer Section ******************************************/
    mapping(address => address[]) RawProductAtManufacturer;

    function  rawProductReceiver(
        address pid
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );

        RawMatrials(pid).receivedPackage(msg.sender);   
        RawProductAtManufacturer[msg.sender].push(pid);     
    }

    function getPackageCount() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawProductAtManufacturer[msg.sender].length;
    }

    function getBatchIDByIndex(uint index) public view returns(address BatchID){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawProductAtManufacturer[msg.sender][index];
    }

    mapping(address => address[]) ManufacturermadicineBatches;
    event MadicineNewBatch(
        address indexed BatchId, 
        address indexed Manufacturer, 
        address shipper, 
        address indexed Receiver
    );

    function manufacturMadicine(
        bytes32 Des,
        bytes32 RM,
        uint Quant,
        address Shpr,
        address Rcvr,
        uint RcvrType
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        require(
            RcvrType != 0,
            "Receiver Type must be define"
        );

        Madicine m = new Madicine(
            msg.sender,
            Des,
            RM,
            Quant,
            Shpr,
            Rcvr,
            RcvrType
        );

        ManufacturermadicineBatches[msg.sender].push(address(m));
        emit MadicineNewBatch(address(m), msg.sender, Shpr, Rcvr);
    }

    function getCountOfBatches() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer, 
            "Only Manufacturer Can call this function."
        );
        return ManufacturermadicineBatches[msg.sender].length;
    }

    function getBatchIdByIndex(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer, 
            "Only Manufacturer Can call this function."
        );
        return ManufacturermadicineBatches[msg.sender][index];
    }


/********************************************** Wholesaler Section ******************************************/
    mapping(address => address[]) madicineBatchAtWholesaler;
    
    function madicineReceived(
        address batchid,
        address cid
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler || UsersDetails[msg.sender].role == roles.distributer,
            "Only Wholesaler and Distributer can call this function"
        );

        uint rtype = Madicine(batchid).receivedPackage(msg.sender);
        if(rtype == 1){
            madicineBatchAtWholesaler[msg.sender].push(batchid);
        }else if( rtype ==2){
            madicineBatchAtDistributer[msg.sender].push(batchid);
            if(Madicine(batchid).getWDP()[0] != address(0)){
                MadicineW_D(cid).recieveWD(batchid,msg.sender);
            }
        }
    }

    mapping(address => address[]) madicineWtoD;
    mapping(address => address) MadicineWtoDTxContract;

    function transferMadicineWtoD(
        address BatchID,
        address Shipper,
        address Receiver
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler && 
            msg.sender == Madicine(BatchID).getWDP()[0],
            "Only Wholesaler or current owner of package can call this function"
        );
        MadicineW_D wd = new MadicineW_D(
            BatchID,
            msg.sender,
            Shipper,
            Receiver
        );
        madicineWtoD[msg.sender].push(address(wd));
        MadicineWtoDTxContract[BatchID] = address(wd);
    }

    function getCountOfBatchesWD() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.wholesaler, 
            "Only Wholesaler Can call this function."
        );
        return madicineWtoD[msg.sender].length;
    }

    function getBatchIdByIndexWD(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler, 
            "Only Wholesaler Can call this function."
        );
        return madicineWtoD[msg.sender][index];
    }

    function getSubContractWD(address BatchID) public view returns (address SubContract) {
        // require(
        //     UsersDetails[msg.sender].role == roles.wholesaler, 
        //     "Only Wholesaler Can call this function."
        // );
        return MadicineWtoDTxContract[BatchID];
    }

/********************************************** Distributer Section ******************************************/
    mapping(address => address[]) madicineBatchAtDistributer;
    
    mapping(address => address[]) madicineDtoP;

    mapping(address => address) MadicineDtoPTxContract;

    function transferMadicineDtoP(
        address BatchID,
        address Shipper,
        address Receiver
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.distributer && 
            msg.sender == Madicine(BatchID).getWDP()[1],
            "Only Distributer or current owner of package can call this function"
        );
        MadicineD_P dp = new MadicineD_P(
            BatchID,
            msg.sender,
            Shipper,
            Receiver
        );
        madicineDtoP[msg.sender].push(address(dp));
        MadicineDtoPTxContract[BatchID] = address(dp);
    }

    function getCountOfBatchesDP() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.distributer, 
            "Only Distributer Can call this function."
        );
        return madicineDtoP[msg.sender].length;
    }

    function getBatchIdByIndexDP(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.distributer, 
            "Only Distributer Can call this function."
        );
        return madicineDtoP[msg.sender][index];
    }

    function getSubContractDP(address BatchID) public view returns (address SubContract) {
        // require(
        //     UsersDetails[msg.sender].role == roles.distributer, 
        //     "Only Distributer Can call this function."
        // );
        return MadicineDtoPTxContract[BatchID];
    }

/********************************************** Pharma Section ******************************************/
    mapping(address => address[]) madicineBatchAtPharma;

    function madicineRecievedAtPharma(
        address batchid,
        address cid
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.pharma, 
            "Only Pharma Can call this function."
        );
        MadicineD_P(cid).recieveDP(batchid, msg.sender);
        madicineBatchAtPharma[msg.sender].push(batchid);
        sale[batchid] = salestatus(1);
    }

    enum salestatus{ notfound, atpharma, sold, expire, damaged}
    mapping(address => salestatus) sale;
    
    event madicineStatus(
        address BatchID,
        address indexed Pharma,
        uint status
    );

    function updateSaleStatus(
        address BatchID,
        uint Status
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.pharma && 
            msg.sender == Madicine(BatchID).getWDP()[2],
            "Only Pharma or current owner of package can call this function"
        );
        require(sale[BatchID] == salestatus(1), "madicine Must be at Pharma");
        sale[BatchID] = salestatus(Status);

        emit madicineStatus(BatchID, msg.sender, Status);
    }

    function salesInfo(
        address BatchID
    ) public 
    view
    returns(
        uint Status
    ){
        return uint(sale[BatchID]);
    }

    function getBatchIdCountP() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return  madicineBatchAtPharma[msg.sender].length;
    }

    function getBatchIdByIndexP(uint index) public view returns(address BatchID){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return madicineBatchAtPharma[msg.sender][index];
    }
}

/********************************************** Other Contract ******************************************/
/********************************************** RawMatrials ******************************************/
contract RawMatrials {
    address Owner;

    enum packageStatus { atcreator, picked, delivered}
    event ShippmentUpdate(
        address indexed BatchID, 
        address indexed Shipper, 
        address indexed Manufacturer, 
        uint TransporterType, 
        uint Status
    );
    address productid;
    bytes32 description;
    bytes32 farmer_name;
    bytes32 location;
    uint quantity;
    address shipper;
    address manufacturer;
    address supplier;
    packageStatus status;
    bytes32 packageReceiverDescription;
        
    constructor (
        address Splr,
        bytes32 Des, 
        bytes32 FN, 
        bytes32 Loc, 
        uint Quant, 
        address Shpr, 
        address Rcvr
    ) public {
        Owner = Splr;
        productid = address(this);
        description = Des;
        farmer_name = FN;
        location = Loc;
        quantity = Quant;
        shipper = Shpr;
        manufacturer = Rcvr;
        supplier = Splr;
        status = packageStatus(0);
    }

    function getSupplyRawMatrials () public view returns(
        bytes32 Des,
        bytes32 FN,
        bytes32 Loc,
        uint Quant,
        address Shpr,
        address Rcvr,
        address Splr
    ) {
        return(
            description,
            farmer_name,
            location,
            quantity,
            shipper,
            manufacturer,
            supplier
        );
    }

    function getStatusOfRawMatrials() public view returns(
        uint
    ) {
        return uint(status);
    }

    function pickPackage(
        address shpr
    ) public {
        require(
            shpr == shipper,
            "Only Associate Shipper can call this function"
        );
        require(
            status == packageStatus(0),
            "Package must be at Supplier."
        );
        status = packageStatus(1);
        emit ShippmentUpdate(address(this),shipper,manufacturer,1,1);
    }

    function receivedPackage(
        address manu
    ) public {
        
        require(
            manu == manufacturer,
            "Only Associate Manufacturer can call this function"
        );

        require(
            status == packageStatus(1),
            "Product not picked up yet"
        );
        status = packageStatus(2);
        emit ShippmentUpdate(address(this),shipper,manufacturer,1,2);
    }
}

/********************************************** Madicine ******************************************/
contract Madicine {
    
    address Owner;

    enum madicineStatus { atcreator, picked4W, picked4D, deliveredatW, deliveredatD, picked4P, deliveredatP}

    // address batchid;
    bytes32 description;
    bytes32 rawmatriales;
    uint quantity;
    address shipper;
    address manufacturer;
    address wholesaler;
    address distributer;
    address pharma;
    madicineStatus status;    

    event ShippmentUpdate(
        address indexed BatchID, 
        address indexed Shipper, 
        address indexed Receiver, 
        uint TransporterType, 
        uint Status
    );

    constructor(
        address Manu,
        bytes32 Des,
        bytes32 RM,
        uint Quant,
        address Shpr,
        address Rcvr,
        uint RcvrType
    ) public {
        Owner = Manu;
        manufacturer = Manu;
        description = Des;
        rawmatriales = RM;
        quantity = Quant;
        shipper = Shpr;
        if(RcvrType == 1) {
            wholesaler = Rcvr;
        } else if( RcvrType == 2){
            distributer = Rcvr;
        }
    }

    function getmadicineInfo () public view returns(
        address Manu,
        bytes32 Des,
        bytes32 RM,
        uint Quant,
        address Shpr
    ) {
        return(
            manufacturer,
            description,
            rawmatriales,
            quantity,
            shipper
        );
    }

    function getWDP() public view returns(
        address[3] memory WDP 
    ) {
        return (
            [wholesaler,distributer,pharma]
        );
    }

    function getStatusOfBatchID() public view returns(
        uint
    ) {
        return uint(status);
    }

    function pickPackage(
        address shpr
    ) public {
        require(
            shpr == shipper,
            "Only Associate Shipper can call this function"
        );
        require(
            status == madicineStatus(0),
            "Package must be at Supplier."
        );
    
        if(wholesaler!=address(0x0)){
            status = madicineStatus(1);
            emit ShippmentUpdate(address(this),shipper,wholesaler,1,1);
        }else{
            status = madicineStatus(2);
            emit ShippmentUpdate(address(this),shipper,distributer,1,1);
        }
    }

    function receivedPackage(
        address Rcvr
    ) public 
    returns(uint rcvtype)
    {
        
        require(
            Rcvr == wholesaler || Rcvr == distributer,
            "Only Associate Wholesaler or Distrubuter can call this function"
        );

        require(
            uint(status) >= 1,
            "Product not picked up yet"
        );

        if(Rcvr == wholesaler && status == madicineStatus(1)){
            status = madicineStatus(3);
            emit ShippmentUpdate(address(this),shipper,wholesaler,2,3);
            return 1;
        } else if(Rcvr == distributer && status == madicineStatus(2)){
            status = madicineStatus(4);
            emit ShippmentUpdate(address(this),shipper,distributer,3,4);
            return 2;
        }
    }

    function sendWD(
        address receiver,
        address sender
    ) public {
        require(
            wholesaler == sender,
            "this Wholesaler is not Associated."
        );
        distributer = receiver;
        status = madicineStatus(2);
    }

    function recievedWD(
        address receiver
    ) public {
        require(
            distributer == receiver,
            "This Distributer is not Associated."
        );
        status = madicineStatus(4);
    }

    function sendDP(
        address receiver,
        address sender
    ) public {
        require(
            distributer == sender,
            "this Distributer is not Associated."
        );
        pharma = receiver;
        status = madicineStatus(5);
    }

    function recievedDP(
        address receiver
    ) public {
        require(
            pharma == receiver,
            "This Pharma is not Associated."
        );
        status = madicineStatus(6);
    }
}

/********************************************** MadicineW_D ******************************************/
contract MadicineW_D {
    address Owner;

    enum packageStatus { atcreator, picked, delivered}

    address batchid;
    address sender;
    address shipper;
    address receiver;
    packageStatus status;

    constructor(
        address BatchID,
        address Sender,
        address Shipper,
        address Receiver
    ) public {
        Owner = Sender;
        batchid = BatchID;
        sender = Sender;
        shipper = Shipper;
        receiver = Receiver;
        status = packageStatus(0);

       
    }

    function pickWD(
        address BatchID,
        address Shipper
    ) public {
        require(
            Shipper == shipper,
            "Only Associated shipper can call this function."
        );
        status = packageStatus(1);
        
         Madicine(BatchID).sendWD(
            receiver,
            sender
        );
    }

    function recieveWD(
        address BatchID,
        address Receiver
    ) public {
        require(
            Receiver == receiver,
            "Only Associated receiver can call this function."
        );
        status = packageStatus(2);
        
        Madicine(BatchID).recievedWD(
            Receiver
        );
    }
    
    function getStatusOfBatchID() public view returns(
        uint
    ) {
        return uint(status);
    }

}

/********************************************** MadicineD_P ******************************************/
contract MadicineD_P {
    address Owner;

    enum packageStatus { atcreator, picked, delivered}

    address batchid;
    address sender;
    address shipper;
    address receiver;
    packageStatus status;

    constructor(
        address BatchID,
        address Sender,
        address Shipper,
        address Receiver
    ) public {
        Owner = Sender;
        batchid = BatchID;
        sender = Sender;
        shipper = Shipper;
        receiver = Receiver;
        status = packageStatus(0);
    }

    function pickDP(
        address BatchID,
        address Shipper
    ) public {
        require(
            Shipper == shipper,
            "Only Associated shipper can call this function."
        );
        status = packageStatus(1);
        
        Madicine(BatchID).sendDP(
            receiver,
            sender
        );
    }

    function recieveDP(
        address BatchID,
        address Receiver
    ) public {
        require(
            Receiver == receiver,
            "Only Associated receiver can call this function."
        );
        status = packageStatus(2);
        
        Madicine(BatchID).recievedDP(
            Receiver
        );
    }

    function getStatusOfBatchID() public view returns(
        uint
    ) {
        return uint(status);
    }

}


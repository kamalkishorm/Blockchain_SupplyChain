pragma solidity >=0.4.25 <0.6.0;

contract SupplyChain_OLD {

    constructor() public {
        Owner = msg.sender;
    }
/********************************************** Owner Section *********************************************/
    address public Owner;
    modifier onlyOwner() {
        require(
            msg.sender == Owner,
            "Only owner can call this function."
        );
        _;
    }
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
    enum packageStatus { atcreator, picked, delivered}
    struct RawProductInfo {
        bytes32 productid;
        bytes32 description;
        bytes32 farmer_name;
        bytes32 location;
        uint quantity;
        address shipper;
        address receiver;
        address supplier;
        packageStatus status;
        // bytes32 transporter_route;
        bytes32 packageReceiverDescription;
    }

    mapping(bytes32 => RawProductInfo) RawProductDetails;
    mapping(address => bytes32[]) supplierRawProductInfo;

    event RawSupplyInit(
        bytes32 indexed ProductID, 
        address indexed Supplier, 
        address Shipper, 
        address indexed Receiver
    );

    function supplyRaw(
        bytes32 Description, 
        bytes32 FarmerName, 
        bytes32 Location, 
        uint Quantity, 
        address Shipper, 
        address Receiver
        ) public {
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        bytes32 pid = keccak256(abi.encodePacked(msg.sender, block.number, Quantity));
        RawProductDetails[pid].productid = pid;
        RawProductDetails[pid].description = Description;
        RawProductDetails[pid].farmer_name = FarmerName;
        RawProductDetails[pid].location = Location;
        RawProductDetails[pid].quantity = Quantity;
        RawProductDetails[pid].shipper = Shipper;
        RawProductDetails[pid].receiver = Receiver;
        RawProductDetails[pid].supplier = msg.sender;
        RawProductDetails[pid].status = packageStatus(0);

        supplierRawProductInfo[msg.sender].push(pid);
        emit RawSupplyInit(pid, msg.sender, Shipper, Receiver);
    }

    function getCountOfProducts() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender].length;
    }

    function getProductIdByIndex(uint index) public view returns(bytes32 BatchID) {
        require(
            UsersDetails[msg.sender].role == roles.supplier, 
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender][index];
    }

    function getSupplyRaw(
        bytes32 pid
        ) public
        view
        returns(
            bytes32 description,
            bytes32 farmer_name,
            bytes32 location,
            uint quantity,
            address shipper,
            address receiver,
            address supplier
        ) {
        return(
            RawProductDetails[pid].description,
            RawProductDetails[pid].farmer_name,
            RawProductDetails[pid].location,
            RawProductDetails[pid].quantity,
            RawProductDetails[pid].shipper,
            RawProductDetails[pid].receiver,
            RawProductDetails[pid].supplier
        );
    }

    function getStatusOfRawMatrials(
        bytes32 pid
    ) public
    view
    returns(
        uint status
    ) {
        return uint(RawProductDetails[pid].status);
    }
/********************************************** Transporter Section ***************************************/
    event ShippmentUpdate(
        bytes32 indexed BatchId, 
        address indexed Shipper, 
        address indexed receiver, 
        uint transportertype, 
        uint status
    );

    function loadpacakage(bytes32 pid, uint transportertype, uint receivertype) public {
        require(
            UsersDetails[msg.sender].role == roles.transporter,
            "Only Transporter can call this function"
        );
        require(
            transportertype > 0,
            "Transporter Type must be define"
        );

        if(transportertype == 1) {  // Supplier to Manufacturer
            require(
                msg.sender == RawProductDetails[pid].shipper,
                "Transporter is other user"
            );
            RawProductDetails[pid].status = packageStatus(1);
            emit ShippmentUpdate(pid, msg.sender, RawProductDetails[pid].receiver,1,1);
        } else if(transportertype == 2) {   // Manufacturer to Wholesaler OR Manufacturer to Distributer
            require(
                msg.sender == MedicineBatchDetails[pid].shipper,
                "Transporter is other user"
            );
            require(receivertype != 0,"Receiver Type must be define");
            MedicineBatchDetails[pid].status = medicineStatus(receivertype);
            if(receivertype == 1){
                emit ShippmentUpdate(pid, msg.sender, MedicineBatchDetails[pid].wholesaler,2,1);
            } else if(receivertype == 2){
                emit ShippmentUpdate(pid, msg.sender, MedicineBatchDetails[pid].manufacturer,2,2);
            }
        } else if(transportertype == 3) {   // Wholesaler to Distributer
            require(
                msg.sender == MedicineWtoD[pid].shipper,
                "Transporter is other user"
            );
            MedicineWtoD[pid].status = packageStatus(1);
            emit ShippmentUpdate(pid, msg.sender, MedicineWtoD[pid].receiver,1,1);
        } else if(transportertype == 4) {   // Distrubuter to Pharma
            require(
                msg.sender == MedicineDtoR[pid].shipper,
                "Transporter is other user"
            );
            MedicineDtoR[pid].status = packageStatus(1);
            MedicineBatchDetails[pid].status = medicineStatus(5);
            emit ShippmentUpdate(pid, msg.sender, MedicineDtoR[pid].receiver,1,1);
        }
    }
/********************************************** Manufacturer Section **************************************/
    mapping(address => bytes32[]) RawProductAtManufacturer;
    // mapping(address => mapping(bytes32 => RawProductInfo)) RawProductDetailsAtManufacturer;

    enum medicineStatus { atcreator, picked4W, picked4D, deliveredatW, deliveredatD, picked4P, deliveredatP}
    
    event RawProductReceive(
        bytes32 indexed BatchID, 
        address indexed shipper, 
        address indexed supplier,
        address receiver
    );

    function rawProductReceived(bytes32 pid) public {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        require(
            RawProductDetails[pid].productid == pid,
            "Product does not exist"
        );
        require(
            RawProductDetails[pid].status == packageStatus(1),
            "Product not picked up yet"
        );
        require(
            msg.sender == RawProductDetails[pid].receiver,
            "Manufacturer is different"
        );
        RawProductDetails[pid].status = packageStatus(2);
        // RawProductDetailsAtManufacturer[msg.sender][pid] = RawProductDetails[pid];

        RawProductAtManufacturer[msg.sender].push(pid);
        emit RawProductReceive(pid,RawProductDetails[pid].shipper, RawProductDetails[pid].supplier, msg.sender);
    }

    struct MedicineBatch{
        bytes32 batchid;
        bytes32 description;
        bytes32 rawmatriales;
        uint quantity;
        address shipper;
        address manufacturer;
        address wholesaler;
        address distributer;
        address pharma;
        medicineStatus status;
    }

    mapping(bytes32 => MedicineBatch) MedicineBatchDetails;
    mapping(address => bytes32[]) ManufacturerMedicineBatches;

    event MadicineNewBatch(
        bytes32 indexed BatchId, 
        address indexed Manufacturer, 
        address shipper, 
        address indexed Reciever
    );

    function newBatch(
        bytes32 Description,
        bytes32 RawMatrials,
        uint Quantity,
        address Shipper,
        address Receiver,
        uint receivertype
        ) public {
    
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        require(
            receivertype != 0,
            "Receiver Type must be define"
        );
        bytes32 batchID = keccak256(abi.encodePacked(msg.sender, block.number, Quantity));
        MedicineBatchDetails[batchID].batchid = batchID;
        MedicineBatchDetails[batchID].description = Description;
        MedicineBatchDetails[batchID].rawmatriales = RawMatrials;
        MedicineBatchDetails[batchID].quantity = Quantity;
        MedicineBatchDetails[batchID].shipper = Shipper;
        MedicineBatchDetails[batchID].manufacturer = msg.sender;
        MedicineBatchDetails[batchID].status = medicineStatus(0);
        if(receivertype == 1){
            MedicineBatchDetails[batchID].wholesaler = Receiver;
        } else if(receivertype == 2){
            MedicineBatchDetails[batchID].distributer = Receiver;
        }

        ManufacturerMedicineBatches[msg.sender].push(batchID);

        emit MadicineNewBatch(batchID, msg.sender, Shipper, Receiver);
    }

    function getMadicineBatchCount() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawProductAtManufacturer[msg.sender].length;
    }

    function getBatchIDByIndex(uint index) public view returns(bytes32 BatchID){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawProductAtManufacturer[msg.sender][index];
    }

    function getMadicineInfo(
        bytes32 batchID
    ) public 
    view
    returns(
        bytes32 Description,
        bytes32 RawMatrials,
        uint Quantity,
        address Shipper,
        address Manufacturer
    ) {
        return (
            MedicineBatchDetails[batchID].description,
            MedicineBatchDetails[batchID].rawmatriales,
            MedicineBatchDetails[batchID].quantity,
            MedicineBatchDetails[batchID].shipper,
            MedicineBatchDetails[batchID].manufacturer
        );
    }

    function getWDP(
        bytes32 batchID
    ) public
    view
    returns(
        address Wholesaler,
        address Distributer,
        address Pharma
    ) {
        return (
            MedicineBatchDetails[batchID].wholesaler,
            MedicineBatchDetails[batchID].distributer,
            MedicineBatchDetails[batchID].pharma
        );
    }

    function getMedicineStatus(
        bytes32 BatchID
    ) public
    view
    returns (
        uint status
    ){
        return uint(MedicineBatchDetails[BatchID].status);
    }
/********************************************** Wholesaler Section ****************************************/

    mapping(address => bytes32[]) MedicineBatchAtWholesaler;

    event MedicineReceive(
        bytes32 indexed BathcID, 
        address indexed Sender,
        address indexed Shipper,
        address Receiver
    );

    function medicineReceived(bytes32 pid) public {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler || UsersDetails[msg.sender].role == roles.distributer,
            "Only Wholesaler and Distributer can call this function"
        );
        require(
            MedicineBatchDetails[pid].batchid == pid,
            "Product does not exist"
        );
        require(
            uint(MedicineBatchDetails[pid].status) >= 1,
            "Product not picked up yet"
        );
        
        MedicineBatchDetails[pid].status = medicineStatus(uint(UsersDetails[msg.sender].role)-1);
        if(UsersDetails[msg.sender].role == roles.wholesaler) {
            require(
                msg.sender == MedicineBatchDetails[pid].wholesaler,
                "Wholesaler is different"
            );
            MedicineBatchAtWholesaler[msg.sender].push(pid);
            emit MedicineReceive(pid, MedicineBatchDetails[pid].manufacturer, MedicineBatchDetails[pid].shipper,msg.sender);
        }else if(UsersDetails[msg.sender].role == roles.distributer){
            require(
                msg.sender == MedicineBatchDetails[pid].distributer,
                "Distributer is different"
            );
            if(MedicineBatchDetails[pid].wholesaler!=address(0)){
                MedicineWtoD[pid].status = packageStatus(2);
                emit MedicineReceive(pid, MedicineWtoD[pid].sender, MedicineWtoD[pid].shipper,msg.sender);
            }else{
                emit MedicineReceive(pid, MedicineBatchDetails[pid].manufacturer, MedicineBatchDetails[pid].shipper,msg.sender);
            }
            MedicineBatchAtDistributer[msg.sender].push(pid);
        }
        
    }

    struct Medicine_WtoD{
        bytes32 batchid;
        address sender;
        address shipper;
        address receiver;
        packageStatus status;
    }
    mapping(bytes32 => Medicine_WtoD) MedicineWtoD;

    event MedicineTransportWtoD(
        bytes32 indexed BatchID,
        address indexed Shipper,
        address indexed Receiver,
        address Sender
    );

    function shipMedicineWtoD(
        bytes32 BatchID,
        address Shipper,
        address Receiver
    ) public 
    {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler && msg.sender == MedicineBatchDetails[BatchID].wholesaler,
            "Only Wholesaler or current owner of package can call this function"
        );
        MedicineWtoD[BatchID].batchid = BatchID;
        MedicineWtoD[BatchID].shipper = Shipper;
        MedicineWtoD[BatchID].receiver = Receiver;
        MedicineWtoD[BatchID].status = packageStatus(0);
        MedicineWtoD[BatchID].sender = msg.sender;
        MedicineBatchDetails[BatchID].distributer = Receiver;
        MedicineBatchDetails[BatchID].status = medicineStatus(2);
        
        emit MedicineTransportWtoD(BatchID, Shipper, Receiver, msg.sender);
    }

    function shipInfoWtoD(
        bytes32 BatchID
    ) public
    view
    returns(
        address shipper,
        address receiver,
        uint status
    ) {
        return (
            MedicineWtoD[BatchID].shipper,
            MedicineWtoD[BatchID].receiver,
            uint(MedicineWtoD[BatchID].status)
        );
    }

    function getBatchIdCountW() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.wholesaler,
            "Only Wholesaler or current owner of package can call this function"
        );
        return  MedicineBatchAtWholesaler[msg.sender].length;
    }

    function getBatchIdByIndexW(uint index) public view returns(bytes32 BatchID){
        require(
            UsersDetails[msg.sender].role == roles.wholesaler,
            "Only Wholesaler or current owner of package can call this function"
        );
        return MedicineBatchAtWholesaler[msg.sender][index];
    }

/********************************************** Distributer Section ***************************************/
    mapping(address => bytes32[]) MedicineBatchAtDistributer;

    event MedicineShipToPharma(
        bytes32 indexed BatchID,
        address indexed Shipper,
        address indexed Receiver,
        address Sender
    );

    struct Medicine_DtoR{
        bytes32 batchid;
        address shipper;
        address receiver;
        address sender;
        packageStatus status;
    }
    mapping(bytes32 => Medicine_DtoR) MedicineDtoR;

    function shipMedicineDtoP(
        bytes32 BatchID,
        address Shipper,
        address Receiver
    ) public 
    {
        require(
            UsersDetails[msg.sender].role == roles.distributer && msg.sender == MedicineBatchDetails[BatchID].distributer,
            "Only Distributer or current owner of package can call this function"
        );
        MedicineDtoR[BatchID].batchid = BatchID;
        MedicineDtoR[BatchID].shipper = Shipper;
        MedicineDtoR[BatchID].receiver = Receiver;
        MedicineDtoR[BatchID].status = packageStatus(0);
        MedicineDtoR[BatchID].sender = msg.sender;
        MedicineBatchDetails[BatchID].pharma = Receiver;
        // MedicineBatchDetails[BatchID].status = medicineStatus(5);

        emit MedicineShipToPharma(BatchID, Shipper, Receiver, msg.sender);
    }

    function shipInfoDtoP(
        bytes32 BatchID
    ) public
    view
    returns(
        address shipper,
        address receiver,
        uint status
    ) {
        return (
            MedicineDtoR[BatchID].shipper,
            MedicineDtoR[BatchID].receiver,
            uint(MedicineDtoR[BatchID].status)
        );
    }

    function getBatchIdCountD() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.distributer,
            "Only Wholesaler or current owner of package can call this function"
        );
        return  MedicineBatchAtDistributer[msg.sender].length;
    }

    function getBatchIdByIndexD(uint index) public view returns(bytes32 BatchID){
        require(
            UsersDetails[msg.sender].role == roles.distributer,
            "Only Wholesaler or current owner of package can call this function"
        );
        return MedicineBatchAtDistributer[msg.sender][index];
    }
/********************************************** Pharma Section ******************************************/
    enum salestatus{ notfound, atpharma, sold, expire, damaged}
    mapping(address => bytes32[]) MedicineBatchAtPharma;
    mapping(bytes32 => salestatus) sale;

    event MedicineReceiveAtPharma(
        bytes32 indexed BatchID,
        address indexed Shipper,
        address indexed Sender,
        address Receiver
    );
    event MedicineStatus(
        bytes32 BatchID,
        address indexed Pharma,
        uint status
    );

    function receiveMedicineFormD(
        bytes32 BatchID
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.pharma && msg.sender == MedicineBatchDetails[BatchID].pharma,
            "Only Pharma or current owner of package can call this function"
        );
        MedicineDtoR[BatchID].status = packageStatus(2);
        MedicineBatchDetails[BatchID].status = medicineStatus(6);
        MedicineBatchAtPharma[msg.sender].push(BatchID);
        sale[BatchID] = salestatus(1);

        emit MedicineReceiveAtPharma(BatchID, MedicineDtoR[BatchID].shipper, MedicineDtoR[BatchID].sender, msg.sender);
    }

    function updateSaleStatus(
        bytes32 BatchID,
        uint Status
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.pharma && msg.sender == MedicineBatchDetails[BatchID].pharma,
            "Only Pharma or current owner of package can call this function"
        );
        require(sale[BatchID] == salestatus(1), "Medicine Must be at Pharma");
        sale[BatchID] = salestatus(Status);

        emit MedicineStatus(BatchID, msg.sender, Status);
    }

    function salesInfo(
        bytes32 BatchID
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
        return  MedicineBatchAtPharma[msg.sender].length;
    }

    function getBatchIdByIndexP(uint index) public view returns(bytes32 BatchID){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return MedicineBatchAtPharma[msg.sender][index];
    }
}
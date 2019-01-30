pragma solidity >=0.4.25 <0.6.0;
/// @title Blockchain : Pharmaceutical SupplyChain
/// @author Kamal Kishor Mehra
contract SupplyChain {

    /// @notice
    address public Owner;

    /// @notice
    /// @dev Initiate SupplyChain Contract
    constructor () public {
        Owner = msg.sender;
    }
/********************************************** Owner Section *********************************************/
    /// @dev Validate Owner
    modifier onlyOwner() {
        require(
            msg.sender == Owner,
            "Only owner can call this function."
        );
        _;
    }

    enum roles {
        norole,
        supplier,
        transporter,
        manufacturer,
        wholesaler,
        distributer,
        pharma,
        revoke
    }

    event UserRegister(address indexed EthAddress, bytes32 Name);
    event UserRoleRevoked(address indexed EthAddress, bytes32 Name, uint Role);
    event UserRoleRessigne(address indexed EthAddress, bytes32 Name, uint Role);

    /// @notice
    /// @dev Register New user by Owner
    /// @param EthAddress Ethereum Network Address of User
    /// @param Name User name
    /// @param Location User Location
    /// @param Role User Role
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
    /// @notice
    /// @dev Revoke users role
    /// @param userAddress User Ethereum Network Address
    function revokeRole(address userAddress) public onlyOwner {
        require(UsersDetails[userAddress].role != roles.norole, "User not registered");
        emit UserRoleRevoked(userAddress, UsersDetails[userAddress].name,uint(UsersDetails[userAddress].role));
        UsersDetails[userAddress].role = roles(7);
    }
    /// @notice
    /// @dev Reassigne new role to User
    /// @param userAddress User Ethereum Network Address
    /// @param Role Role to assigne
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

    /// @notice
    mapping(address => UserInfo) UsersDetails;
    /// @notice
    address[] users;

    /// @notice
    /// @dev Get User Information/ Profile
    /// @param User User Ethereum Network Address
    /// @return User Details
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

    /// @notice
    /// @dev Get Number of registered Users
    /// @return Number of registered Users
    function getUsersCount() public view returns(uint count){
        return users.length;
    }

    /// @notice
    /// @dev Get User by Index value of stored data
    /// @param index Indexed Number
    /// @return User Details
    function getUserbyIndex(uint index) public view returns(
        bytes32 name,
        bytes32 location,
        address ethAddress,
        roles role
        ) {
        return getUserInfo(users[index]);
    }
/********************************************** Supplier Section ******************************************/
    /// @notice
    mapping(address => address[]) supplierRawProductInfo;
    event RawSupplyInit(
        address indexed ProductID,
        address indexed Supplier,
        address Shipper,
        address indexed Receiver
    );

    /// @notice
    /// @dev Create new raw package by Supplier
    /// @param Des Transporter Ethereum Network Address
    /// @param Rcvr Manufacturer Ethereum Network Address
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

    /// @notice
    /// @dev  Get Count of created package by supplier(caller)
    /// @return Number of packages
    function getPackagesCountS() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.supplier,
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender].length;
    }

    /// @notice
    /// @dev Get PackageID by Indexed value of stored data
    /// @param index Indexed Value
    /// @return PackageID
    function getPackageIdByIndexS(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.supplier,
            "Only Supplier Can call this function "
        );
        return supplierRawProductInfo[msg.sender][index];
    }

/********************************************** Transporter Section ******************************************/

    /// @notice
    /// @dev Load Consingment fot transport one location to another.
    /// @param pid PackageID or MadicineID
    /// @param transportertype Transporter Type on the basic of tx between Roles
    /// @param cid Sub Contract ID for Consingment transaction
    function loadConsingment(
        address pid, //Package or Batch ID
        uint transportertype,
        address cid
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
        } else if(transportertype == 3) {   // Wholesaler to Distributer
            MadicineW_D(cid).pickWD(pid,msg.sender);
        } else if(transportertype == 4) {   // Distrubuter to Pharma
            MadicineD_P(cid).pickDP(pid,msg.sender);
        }
    }

/********************************************** Manufacturer Section ******************************************/
    /// @notice
    mapping(address => address[]) RawPackagesAtManufacturer;

    /// @notice
    /// @dev Update Package / Madicine batch recieved status by ethier Manufacturer or Distributer
    /// @param pid  PackageID or MadicineID
    function  rawPackageReceived(
        address pid
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );

        RawMatrials(pid).receivedPackage(msg.sender);
        RawPackagesAtManufacturer[msg.sender].push(pid);
    }

    /// @notice
    /// @dev Get Package Count at Manufacturer
    /// @return Number of Packages at Manufacturer
    function getPackagesCountM() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawPackagesAtManufacturer[msg.sender].length;
    }

    /// @notice
    /// @dev Get PackageID by Indexed value of stored data
    /// @param index Indexed Value
    /// @return PackageID
    function getPackageIDByIndexM(uint index) public view returns(address BatchID){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only manufacturer can call this function"
        );
        return RawPackagesAtManufacturer[msg.sender][index];
    }

    /// @notice
    mapping(address => address[]) ManufactureredMadicineBatches;
    event MadicineNewBatch(
        address indexed BatchId,
        address indexed Manufacturer,
        address shipper,
        address indexed Receiver
    );

    /// @notice
    /// @dev Create Madicine Batch
    /// @param Des Description of madicine batch
    /// @param RM RawMatrials Information
    /// @param Quant Number of Units
    /// @param Shpr Transporter Ethereum Network Address
    /// @param Rcvr Receiver Ethereum Network Address
    /// @param RcvrType Receiver Type Ethier Wholesaler(1) or Distributer(2)
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

        ManufactureredMadicineBatches[msg.sender].push(address(m));
        emit MadicineNewBatch(address(m), msg.sender, Shpr, Rcvr);
    }

    /// @notice
    /// @dev Get Madicine Batch Count
    /// @return Number of Batches
    function getBatchesCountM() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only Manufacturer Can call this function."
        );
        return ManufactureredMadicineBatches[msg.sender].length;
    }

    /// @notice
    /// @dev Get Madicine BatchID by indexed value of stored data
    /// @param index Indexed Number
    /// @return Madicine BatchID
    function getBatchIdByIndexM(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.manufacturer,
            "Only Manufacturer Can call this function."
        );
        return ManufactureredMadicineBatches[msg.sender][index];
    }


/********************************************** Wholesaler Section ******************************************/
    /// @notice
    mapping(address => address[]) MadicineBatchesAtWholesaler;

    /// @notice
    /// @dev Madicine Batch Received
    /// @param batchid Madicine BatchID
    /// @param cid Sub Contract ID for Madicine (if transaction Wholesaler to Distributer)
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
            MadicineBatchesAtWholesaler[msg.sender].push(batchid);
        }else if( rtype == 2){
            MadicineBatchesAtWholesaler[msg.sender].push(batchid);
            if(Madicine(batchid).getWDP()[0] != address(0)){
                MadicineW_D(cid).recieveWD(batchid,msg.sender);
            }
        }
    }

    /// @notice
    mapping(address => address[]) MadicineWtoD;
    /// @notice
    mapping(address => address) MadicineWtoDTxContract;

    /// @notice
    /// @dev Sub Contract for Madicine Transfer from Wholesaler to Distributer
    /// @param BatchID Madicine BatchID
    /// @param Shipper Transporter Ethereum Network Address
    /// @param Receiver Distributer Ethereum Network Address
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
        MadicineWtoD[msg.sender].push(address(wd));
        MadicineWtoDTxContract[BatchID] = address(wd);
    }

    /// @notice
    /// @dev Get Madicine Batch Count
    /// @return Number of Batches
    function getBatchesCountWD() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.wholesaler,
            "Only Wholesaler Can call this function."
        );
        return MadicineWtoD[msg.sender].length;
    }

    /// @notice
    /// @dev Get Madicine BatchID by indexed value of stored data
    /// @param index Indexed Number
    /// @return Madicine BatchID
    function getBatchIdByIndexWD(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.wholesaler,
            "Only Wholesaler Can call this function."
        );
        return MadicineWtoD[msg.sender][index];
    }

    /// @notice
    /// @dev Get Sub Contract ID of Madicine Batch Transfer in between Wholesaler to Distributer
    /// @param BatchID Madicine BatchID
    /// @return SubContract ID
    function getSubContractWD(address BatchID) public view returns (address SubContractWD) {
        // require(
        //     UsersDetails[msg.sender].role == roles.wholesaler,
        //     "Only Wholesaler Can call this function."
        // );
        return MadicineWtoDTxContract[BatchID];
    }

/********************************************** Distributer Section ******************************************/
    /// @notice
    mapping(address => address[]) MadicineBatchAtDistributer;

    /// @notice
    mapping(address => address[]) MadicineDtoP;

    /// @notice
    mapping(address => address) MadicineDtoPTxContract;

    /// @notice
    /// @dev Transfer Madicine BatchID in between Distributer to Pharma
    /// @param BatchID Madicine BatchID
    /// @param Shipper Transporter Ethereum Network Address
    /// @param Receiver Pharma Ethereum Network Address
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
        MadicineDtoP[msg.sender].push(address(dp));
        MadicineDtoPTxContract[BatchID] = address(dp);
    }

    /// @notice
    /// @dev Get Madicine BatchID Count
    /// @return Number of Batches
    function getBatchesCountDP() public view returns (uint count){
        require(
            UsersDetails[msg.sender].role == roles.distributer,
            "Only Distributer Can call this function."
        );
        return MadicineDtoP[msg.sender].length;
    }

    /// @notice
    /// @dev Get Madicine BatchID by indexed value of stored data
    /// @param index Index Number
    /// @return Madicine BatchID
    function getBatchIdByIndexDP(uint index) public view returns(address packageID) {
        require(
            UsersDetails[msg.sender].role == roles.distributer,
            "Only Distributer Can call this function."
        );
        return MadicineDtoP[msg.sender][index];
    }

    /// @notice
    /// @dev Get SubContract ID of Madicine Batch Transfer in between Distributer to Pharma
    /// @param BatchID Madicine BatchID
    /// @return SubContract ID
    function getSubContractDP(address BatchID) public view returns (address SubContractDP) {
        // require(
        //     UsersDetails[msg.sender].role == roles.distributer,
        //     "Only Distributer Can call this function."
        // );
        return MadicineDtoPTxContract[BatchID];
    }

/********************************************** Pharma Section ******************************************/
    /// @notice
    mapping(address => address[]) MadicineBatchAtPharma;

    /// @notice
    /// @dev Madicine Batch Recieved
    /// @param batchid Madicine BatchID
    /// @param cid SubContract ID
    function madicineRecievedAtPharma(
        address batchid,
        address cid
    ) public {
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Pharma Can call this function."
        );
        MadicineD_P(cid).recieveDP(batchid, msg.sender);
        MadicineBatchAtPharma[msg.sender].push(batchid);
        sale[batchid] = salestatus(1);
    }

    enum salestatus {
        notfound,
        atpharma,
        sold,
        expire,
        damaged
    }

    /// @notice
    mapping(address => salestatus) sale;

    event MadicineStatus(
        address BatchID,
        address indexed Pharma,
        uint status
    );

    /// @notice
    /// @dev Update Madicine Batch status
    /// @param BatchID Madicine BatchID
    /// @param Status Madicine Batch Status ( sold, expire etc.)
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

        emit MadicineStatus(BatchID, msg.sender, Status);
    }

    /// @notice
    /// @dev Get Madicine Batch status
    /// @param BatchID Madicine BatchID
    /// @return Status
    function salesInfo(
        address BatchID
    ) public
    view
    returns(
        uint Status
    ){
        return uint(sale[BatchID]);
    }

    /// @notice
    /// @dev Get Madicine Batch count
    /// @return Number of Batches
    function getBatchesCountP() public view returns(uint count){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return  MadicineBatchAtPharma[msg.sender].length;
    }

    /// @notice
    /// @dev Get Madicine BatchID by indexed value of stored data
    /// @param index Index Number
    /// @return ,Madicine BatchID
    function getBatchIdByIndexP(uint index) public view returns(address BatchID){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return MadicineBatchAtPharma[msg.sender][index];
    }
}

/********************************************** Other Contract ******************************************/
/********************************************** RawMatrials ******************************************/
/// @title RawMatrials
/// @notice
/// @dev Create new instance of RawMatrials package
contract RawMatrials {
    /// @notice
    address Owner;

    enum packageStatus { atcreator, picked, delivered}
    event ShippmentUpdate(
        address indexed BatchID,
        address indexed Shipper,
        address indexed Manufacturer,
        uint TransporterType,
        uint Status
    );
    /// @notice
    address productid;
    /// @notice
    bytes32 description;
    /// @notice
    bytes32 farmer_name;
    /// @notice
    bytes32 location;
    /// @notice
    uint quantity;
    /// @notice
    address shipper;
    /// @notice
    address manufacturer;
    /// @notice
    address supplier;
    /// @notice
    packageStatus status;
    /// @notice
    bytes32 packageReceiverDescription;

    /// @notice
    /// @dev Intiate New Package of RawMatrials by Supplier
    /// @param Splr Supplier Ethereum Network Address
    /// @param Des Description of RawMatrials
    /// @param FN Farmer Name
    /// @param Loc Farm Location
    /// @param Quant Number of units in a package
    /// @param Shpr Transporter Ethereum Network Address
    /// @param Rcvr Manufacturer Ethereum Network Address
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

    /// @notice
    /// @dev Get RawMatrials Package Details
    /// @return Package Details
    function getSuppliedRawMatrials () public view returns(
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

    /// @notice
    /// @dev Get Package Transaction Status
    /// @return Package Status
    function getRawMatrialsStatus() public view returns(
        uint
    ) {
        return uint(status);
    }

    /// @notice
    /// @dev Pick Package by Associate Transporter
    /// @param shpr Transporter Ethereum Network Address
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

    /// @notice
    /// @dev Received Package Status Update By Associated Manufacturer
    /// @param manu Manufacturer Ethereum Network Address
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
/// @title Madicine
/// @notice
/// @dev Madicine Batch Information
contract Madicine {

    /// @notice
    address Owner;

    enum madicineStatus {
        atcreator,
        picked4W,
        picked4D,
        deliveredatW,
        deliveredatD,
        picked4P,
        deliveredatP
    }

    // address batchid;
    bytes32 description;
    /// @notice
    bytes32 rawmatriales;
    /// @notice
    uint quantity;
    /// @notice
    address shipper;
    /// @notice
    address manufacturer;
    /// @notice
    address wholesaler;
    /// @notice
    address distributer;
    /// @notice
    address pharma;
    /// @notice
    madicineStatus status;

    event ShippmentUpdate(
        address indexed BatchID,
        address indexed Shipper,
        address indexed Receiver,
        uint TransporterType,
        uint Status
    );

    /// @notice
    /// @dev Create new Madicine Batch by Manufacturer
    /// @param Manu Manufacturer Ethereum Network Address
    /// @param Des Description of Madicine Batch
    /// @param RM RawMatrials for Madicine
    /// @param Quant Number of units
    /// @param Shpr Transporter Ethereum Network Address
    /// @param Rcvr Receiver Ethereum Network Address
    /// @param RcvrType Receiver Type either Wholesaler(1) or Distributer(2)
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

    /// @notice
    /// @dev Get Madicine Batch basic Details
    /// @return Madicine Batch Details
    function getMadicineInfo () public view returns(
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

    /// @notice
    /// @dev Get address Wholesaler, Distributer and Pharma
    /// @return Address Array
    function getWDP() public view returns(
        address[3] memory WDP
    ) {
        return (
            [wholesaler,distributer,pharma]
        );
    }

    /// @notice
    /// @dev Get Madicine Batch Transaction Status
    /// @return Madicine Transaction Status
    function getBatchIDStatus() public view returns(
        uint
    ) {
        return uint(status);
    }

    /// @notice
    /// @dev Pick Madicine Batch by Associate Transporter
    /// @param shpr Transporter Ethereum Network Address
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

    /// @notice
    /// @dev Received Madicine Batch by Associated Wholesaler or Distributer
    /// @param Rcvr Wholesaler or Distributer
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

    /// @notice
    /// @dev Update Madicine Batch transaction Status(Pick) in between Wholesaler and Distributer
    /// @param receiver Distributer Ethereum Network Address
    /// @param sender Wholesaler Ethereum Network Address
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

    /// @notice
    /// @dev Update Madicine Batch transaction Status(Recieved) in between Wholesaler and Distributer
    /// @param receiver Distributer
    function recievedWD(
        address receiver
    ) public {
        require(
            distributer == receiver,
            "This Distributer is not Associated."
        );
        status = madicineStatus(4);
    }

    /// @notice
    /// @dev Update Madicine Batch transaction Status(Pick) in between Distributer and Pharma
    /// @param receiver Pharma Ethereum Network Address
    /// @param sender Distributer Ethereum Network Address
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

    /// @notice
    /// @dev Update Madicine Batch transaction Status(Recieved) in between Distributer and Pharma
    /// @param receiver Pharma Ethereum Network Address
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
/// @title MadicineW_D
/// @notice
/// @dev Sub Contract for Madicine Transaction between Wholesaler and Distributer
contract MadicineW_D {
    /// @notice
    address Owner;

    enum packageStatus { atcreator, picked, delivered}

    /// @notice
    address batchid;
    /// @notice
    address sender;
    /// @notice
    address shipper;
    /// @notice
    address receiver;
    /// @notice
    packageStatus status;

    /// @notice
    /// @dev Create SubContract for Madicine Transaction
    /// @param BatchID Madicine BatchID
    /// @param Sender Wholesaler Ethereum Network Address
    /// @param Shipper Transporter Ethereum Network Address
    /// @param Receiver Distributer Ethereum Network Address
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

    /// @notice
    /// @dev Pick Madicine Batch by Associated Transporter
    /// @param BatchID Madicine BatchID
    /// @param Shipper Transporter Ethereum Network Address
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

    /// @notice
    /// @dev Recieved Madicine Batch by Associate Distributer
    /// @param BatchID Madicine BatchID
    /// @param Receiver Distributer Ethereum Network Address
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

    /// @notice
    /// @dev Get Madicine Batch Transaction status in between Wholesaler and Distributer
    /// @return Transaction status
    function getBatchIDStatus() public view returns(
        uint
    ) {
        return uint(status);
    }

}

/********************************************** MadicineD_P ******************************************/
/// @title MadicineD_P
/// @notice
/// @dev Sub Contract for Madicine Transaction between Distributer and Pharma
contract MadicineD_P {
    /// @notice
    address Owner;

    enum packageStatus { atcreator, picked, delivered}

    /// @notice
    address batchid;
    /// @notice
    address sender;
    /// @notice
    address shipper;
    /// @notice
    address receiver;
    /// @notice
    packageStatus status;

    /// @notice
    /// @dev Create SubContract for Madicine Transaction
    /// @param BatchID Madicine BatchID
    /// @param Sender Distributer Ethereum Network Address
    /// @param Shipper Transporter Ethereum Network Address
    /// @param Receiver Pharma Ethereum Network Address
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

    /// @notice
    /// @dev Pick Madicine Batch by Associated Transporter
    /// @param BatchID Madicine BatchID
    /// @param Shipper Transporter Ethereum Network Address
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

    /// @notice
    /// @dev Recieved Madicine Batch by Associate Distributer
    /// @param BatchID Madicine BatchID
    /// @param Receiver Pharma Ethereum Network Address
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

    /// @notice
    /// @dev Get Madicine Batch Transaction status in between Distributer and Pharma
    /// @return Transaction status
    function getBatchIDStatus() public view returns(
        uint
    ) {
        return uint(status);
    }

}

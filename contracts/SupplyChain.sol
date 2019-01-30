pragma solidity >=0.4.25 <0.6.0;

import './RawMatrials.sol';
import './Madicine.sol';
import './MadicineW_D.sol';
import './MadicineD_P.sol';

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
    /// @return Madicine BatchID
    function getBatchIdByIndexP(uint index) public view returns(address BatchID){
        require(
            UsersDetails[msg.sender].role == roles.pharma,
            "Only Wholesaler or current owner of package can call this function"
        );
        return MadicineBatchAtPharma[msg.sender][index];
    }
}

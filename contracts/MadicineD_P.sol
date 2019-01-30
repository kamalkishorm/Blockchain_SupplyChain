pragma solidity >=0.4.25 <0.6.0;

import './Madicine.sol';

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

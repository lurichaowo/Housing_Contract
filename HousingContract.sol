// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Owned
 * @dev Base contract to represent ownership of a contract
 * @dev Sourced from Mastering Ethereum at https://github.com/ethereumbook/ethereumbook
 */
contract Owned {
	address payable public owner;

	// Contract constructor: set owner
	constructor() {
		owner = msg.sender;
	}
	// Access control modifier
	modifier onlyOwner {
		require(msg.sender == owner,
		        "Only the contract owner can call this function");
		_;
	}
}

/** 
 * @title Mortal
 * @dev Base contract to allow for construct to be destructed
 * @dev Sourced from Mastering Ethereum at https://github.com/ethereumbook/ethereumbook
 */
contract Mortal is Owned {
	// Contract destructor
	function destroy() public onlyOwner {
		selfdestruct(owner);
	}
}

/** 
 * @title HousingContract
 * @dev Implements payment contract system between a landlord and tenents
 */
contract HousingContract is Mortal {

    struct Tenant {
        uint256 id; // unique identifier for tenant
        address payable account; // tenant's billing address 
        uint256 leaseLength; // tenant's lease term in months
    }

    Tenant[] tenants; // list of currently occupied tenants, is dynamic array
    uint256 currTenantCount; // current number of tenants
    uint256 maxTenantCount; // maximum number of tenants allowed
    uint256 securityDepositFee; // initial one-time refundable security deposit fee
    uint256 rentCost; // montly rent cost
    uint256 counter = 0; // counter used to assign tenant ids

    /** 
    * @dev Create a new housing contract to collect rent from tenants
    * @param _maxTenantCount maximum number of tenants allowed
    * @param _securityDepositFee refundable security deposit fee
    * @param _rentCost montly rent cost
    */
    constructor(
        uint256 _maxTenantCount,
        uint256 _securityDepositFee,
        uint256 _rentCost
    ) {
        maxTenantCount = _maxTenantCount;
        _securityDepositFee = securityDepositFee;
        _rentCost = rentCost;
        
        currTenantCount = 0;
        counter = 1;
    }

    //EVENTS
    event RentPayment(
        address indexed _from,
        bytes32 indexed _id,
        uint256 _value
    );

    event SecurityDepositPayment(
        address indexed _from,
        bytes32 indexed _id,
        uint256 _value
    );

    event SecurityDepositRefund(
        address indexed _to,
        bytes32 indexed _id,
        uint256 _value
    );

    /** 
    * @dev Changes monthly rent cost
    * @param newRentCost new montly rent cost
    */
    function changeRent(uint256 newRentCost) public onlyOwner {
        rentCost = newRentCost;
    }

    /** 
    * @dev Charges montly rent to all currently occipied tenants
    */
    function chargeRent() public onlyOwner {}

    /** 
    * @dev Adds tenant to list of tenants and charges security deposit fee
    * @param newTenant payment address of new tenant 
    * @param leaseL tenant's lease term in months
    * newID Generates new Tenant to be added to array of tenants
    */
    function addTenant(address payable newTenant, uint256 leaseL) public onlyOwner {
        /** Check if can house anymore tenants, revert() state of EVM otherwise */
        require(tenants.length < maxTenantCount);

        uint256 newID = counter;
        counter++;
        Tenant memory t = Tenant(newID, newTenant, leaseL);
        tenants.push(t);
    }

    /** 
    * @dev Removes tenant from list of tenants and refunds security deposit fee
    * @param tenantId id of tenant to be removed
    * using swap and delete since no pop function exists
    */
    function removeTenant(uint256 tenantId) public onlyOwner {
        /** Find correct tenant by ID */
        for (uint i = 0; i < tenants.length; i++){
            if (tenants[i].id == tenantId){
                /** Refund security deposit */
                tenants[i].account.transfer(securityDepositFee);

                Tenant memory t = tenants[i];
                tenants[i] = tenants[tenants.length-1];
                tenants[tenants.length-1] = t;
                tenants.pop();
                
                break;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// contract that pays ERC20 token victims of natural disasters if natural disaster event is incoming

contract PayVictims {

    address public treasury;
    IERC20 public USDCtoken;

    mapping(address => uint256) public balances;
    mapping(address => uint) public victimToLocationId; // victim to location id mapping
    mapping(uint => address[]) public locationIdToVictims; // location id to victims mapping
    mapping(address => bool) public isRegisteredVictim; // boolean for registered victim

    event PayVictimsEvent(string disasterType, uint256 amount, address[] victims, uint locId);

    constructor(address _treasury, address _USDCtoken, uint initialBalance) {
        treasury = _treasury;
        USDCtoken = IERC20(_USDCtoken);
        balances[treasury] = initialBalance;
    }


    function registerNewTreasury(address newTreasury) public {
        //change treasury address
        //register treasury
        require(msg.sender == treasury, "only current treasury can register new treasury");
        uint treasuryBalance = balances[treasury];
        balances[treasury] = 0;
        balances[newTreasury] = treasuryBalance;
        treasury = newTreasury;
        USDCtoken.transfer(newTreasury, treasuryBalance);

    }

    function fillTreasury(uint amount) public {
        balances[treasury] += amount;
        USDCtoken.transferFrom(msg.sender, address(this), amount);
    }



    function registerPotentialVictims(address[] memory victims, uint locId) public {
        //register potential victims to treasury
        require(msg.sender == treasury, "only treasury can register victims");
        for (uint256 i = 0; i < victims.length; i++) {
            // Check if the victim is already registered
            if (isRegisteredVictim[victims[i]]) {
                // If victim is already registered, they have moved to a new location
                uint oldLocId = victimToLocationId[victims[i]];
                _removeVictim(oldLocId, victims[i]);
            } else {
                // If victim is not registered, initialize their balance to zero
                balances[victims[i]] = 0;
                isRegisteredVictim[victims[i]] = true; // Mark as registered
            }
            // Update victim's location ID
            victimToLocationId[victims[i]] = locId;
            locationIdToVictims[locId].push(victims[i]);
        }
    }


    // Helper function to remove a victim from a specific location
    function _removeVictim(uint locId, address victim) internal {
        uint length = locationIdToVictims[locId].length;
        for (uint i = 0; i < length; i++) {
            if (locationIdToVictims[locId][i] == victim) {
                // Replace victim to remove with the last victim in the array
                locationIdToVictims[locId][i] = locationIdToVictims[locId][length - 1];
                // Remove the last victim (now duplicated)
                locationIdToVictims[locId].pop();
                break;
            }
        }
    }


    function payVictims(uint locId, uint totalAmount) public {
        //pay victims of natural disaster when validation is complete
        require(msg.sender == treasury, "only treasury can pay victims");
        require(balances[treasury] >= totalAmount, "treasury balance is not enough");
        address[] memory victims = locationIdToVictims[locId];
        uint256 amount = totalAmount / victims.length;
        for (uint256 i = 0; i < victims.length; i++) {
            balances[victims[i]] += amount;
            USDCtoken.transferFrom(address(this), victims[i], amount);
        }

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./mastermind.sol";


contract MastermindFactory {
    Mastermind[] private _masterminds;

    function createMastermind(uint8 _wagerAmount,uint8 _MAX_ROUND)public{
        Mastermind mastermind=new Mastermind(_wagerAmount,_MAX_ROUND);
        _masterminds.push(mastermind);
    }

    function allMastermind()public view returns(Mastermind[] memory ){
       return _masterminds;
    }
}
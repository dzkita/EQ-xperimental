// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {FormulaPlugIn, FormulaParams} from "../src/iterados/plugIns/FormulaPlugIn.sol";

contract Formula is FormulaPlugIn {
    function init(FormulaParams calldata _params) external initializer {
        __init_Forumla(_params);
    }

    function setMinRatio(uint _minRatio)external  {
        _setMinStakeRatio(_minRatio);
    }

    function setDecay(uint _decay)external  {
        _setDecay(_decay);
    }
    function setMaxFlow(uint176 _maxFlow)external  {
        _setMaxFlow(_maxFlow);
    }
}
//  forge test --mc FomrulaTest -vvvv
contract FomrulaTest is Test {

    Formula f;

    function setUp() external {
        f= new Formula();
        f.init(FormulaParams(100,700,10));
    }
    // forge test --mt test_getValues -vvvv
    function test_getValues()external view {

        f.ONE();
        f.ZER0();
        f.MIN_STAKE_RATIO();
        f.MAX_STAKE_RATIO();
        f.decay();
        f.maxFlow();
        f.minStakeRatio();
    }
    // forge test --mt test_setVars -vvvv
    function test_setVars()external{
        
        {
            f.MAX_STAKE_RATIO();
            uint low=1;
            uint high=15100;
            vm.expectRevert();// LOWER_BOUND
            f.setMinRatio(low);
            vm.expectRevert();// HIGHER_BOUND
            f.setMinRatio(high);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {FormulaPlugIn, FormulaParams} from "../src/refactor/plugIns/FormulaPlugIn.sol";

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
    /**
     * @custom:bounds 1 - 1.3e51 (esto hay que confirmar si tiene sentido)
     */
    function setMaxFlow(uint176 _maxFlow)external  {
        _setMaxFlow(_maxFlow);
    }
}
//  forge test --mc FomrulaTest -vvvv
// forge coverage --contracts src/refactor/plugIns   
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
        f.TIME_BOUND();
        f.UNIT();
        f.MAX_FLOW();
        f.decay();
        f.maxFlow();
        f.minStakeRatio();

    }
    // forge test --mt test_setVars -vvvv
    function test_setVars(uint[3] memory _nums )external{
        _nums[0]=bound(_nums[0],11,14999);
        _nums[1]=bound(_nums[1],1,1.3e51);
        _nums[0]=bound(_nums[2],1,15100);
        {
            f.MAX_STAKE_RATIO();
            uint low=1;
            uint high=15100;
            vm.expectRevert();// LOWER_BOUND
            f.setMinRatio(low);
            vm.expectRevert();// HIGHER_BOUND
            f.setMinRatio(high);
            // SUCCESS
            emit log_named_uint('MIN_RATIO',_nums[0]);
            f.setMinRatio(_nums[0]);
        }
        {
            f.MAX_FLOW();
            uint176 h=1.4e51;
            /**
             * @custom:refactor 
             * Un bound bajo no es necesario porque por default es 1
             - > uint176 l=0;
             - > vm.expectRevert();//LOWER_BOUND
             - > f.setMaxFlow(l);
             */

            vm.expectRevert();// HIGHER_BOUND
            f.setMaxFlow(h);
            emit log_named_uint('MAX_FLOW',_nums[1]);
            f.setMaxFlow(uint176(_nums[1]));
        }{  
            /**
             * @custom:continuar
             * Tenemos que seguir los test de esto y afinar los `bounderies` del parametro `decay`
             */
            
            f.setDecay(_nums[2]);
        }
    }
}

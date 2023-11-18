// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './OsmoticFormula.sol';

contract FFormulaOld is OsmoticFormula {

    function init_formula(OsmoticParams calldata _params)  external initializer {
        __OsmoticFormula_init(_params);
    }

    function setOsmoticFormulaParams(OsmoticParams calldata _params) public  {
        _setOsmoticParams(_params);
    }

    function setOsmoticFormulaDecay(uint256 _decay) public  {
        _setOsmoticDecay(_decay);
    }

    function setOsmoticFormulaDrop(uint256 _drop) public  {
        _setOsmoticDrop(_drop);
    }

    function setOsmoticFormulaMaxFlow(uint256 _minStakeRatio) public  {
        _setOsmoticMaxFlow(_minStakeRatio);
    }

    function setOsmoticFormulaMinStakeRatio(uint256 _minFlow) public  {
        _setOsmoticMinStakeRatio(_minFlow);
    }

}
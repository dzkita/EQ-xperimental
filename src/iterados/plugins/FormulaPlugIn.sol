// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {UD60x18, ud, unwrap, convert} from "@prb/math/src/UD60x18.sol";

// Exported struct for better  parameter handling
struct FormulaParams {
    // slot 0 : decay
    uint256 decay;
    // slot 1 : 22/32 (maxFlow) + 10/32 (minStakeRatio)
    uint176 maxFlow;
    uint80 minStakeRatio;
}

abstract contract FormulaPlugIn is Initializable {
    UD60x18 public immutable ONE = convert(1);
    UD60x18 public immutable ZER0 = ud(0);
    /**
     * @custom:bouderies (min,max) reghartding `minStakeRatio`
     * @custom:min 0.01%
     * @custom:max 15 %
     */
    UD60x18 public immutable MIN_STAKE_RATIO = ud(1e16);
    UD60x18 public immutable MAX_STAKE_RATIO = convert(15);
    UD60x18 immutable MIN_FLOW_BOUND = ud(1);
    /**
     * @custom:time-bound min flow 333 days
     * @custom:unit unit == 1e18
     * @custom:max-flow ~ 1.3e51 
        
    ->    1_341_527_745_770_263_265_853_480_621_926_184_377_123_303_681_756_299
     */
    UD60x18 immutable TIME_BOUND = ud(0x1b70380);
    UD60x18 immutable UNIT = ud(0xde0b6b3a7640000);
    UD60x18 immutable MAX_FLOW =
        ud(0x395e918a3d0c184f340b6bdc65da7f8b674ec190c8b);
    /**
     *  @custom:notice 1 UNIT == 1e18 
        1 UNIT == 1_000000000000000000        
                    ^                                
                    |
                    Decimales 
        Como solidity no tiene decimales, le agregamos un buffer de 0 y los usamos como si fueran decimales.

        @custom:var decay == alpha
        Esta variable representa la variacion de voto por unidad de tiempo, quiere decir que, si es 1, por cada segundo que pasa la conviccion varia 1 unidad (tanto para crecer la conviccion como para decrecerla)
       
        @custom:var maxFlow 
        Esto representa la cantidad maxima que de unidades que se pueden madar por unidad de tiempo. Es importante notar que vamos a imponer ciertas limitaciones, por ejemplo que se puedan mandar unidas
        
        @custom:var minStakeRatio 
        La minima cantidad de `stake` necesaria para que un proyecto empiece a recibir fondos de la `pool`
        Este tiene un minima (0.01% ~ 1e16) y una maxima (15% ~ 1.5e19)
     */
    UD60x18 public decay;
    UD60x18 public maxFlow;
    UD60x18 public minStakeRatio;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event FormulaParamsChanged(
        UD60x18 decay,
        UD60x18 maxFlow,
        UD60x18 minStakeRatio
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __init_Forumla(
        FormulaParams calldata _params
    ) internal onlyInitializing {
        _setFormulaParams(_params);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function minStake(uint256 _totalStaked) public view returns (UD60x18) {
        return convert(_totalStaked).mul(minStakeRatio);
    }

    /**
     * @dev targetRate = (1 - sqrt(minStake / min(staked, minStake))) * maxFlow * funds
     */
    function calculateTargetRate(
        uint256 _funds,
        uint256 _stake,
        uint256 _totalStaked
    ) public view returns (UD60x18 _targetRate) {
        if (_stake == 0) {
            _targetRate = ZER0;
        } else {
            UD60x18 _wFunds = convert(_funds);
            UD60x18 _wStake = convert(_stake);
            UD60x18 _wMinStake = convert(_totalStaked);
            UD60x18 _minStake = minStake(_totalStaked);

            _targetRate = (
                ONE.sub(
                    _minStake
                        .div(_wStake > _wMinStake ? _wStake : _wMinStake)
                        .sqrt()
                )
            ).mul(maxFlow.mul(_wFunds));
        }
    }


    /**
     * @notice Get current
     * @dev rate = ( lastRate * [alpha ^ time]) + [_targetRate * (1 - alpha ^ time)]
     * @dev Aca capaz hay que usar un SD59x18 porque puede hacer overflow/underflow
     */
    function calculateRate(
        uint40 _timePassed,
        uint256 _lastRate,
        uint256 _targetRate
    ) public view returns (UD60x18) {
        UD60x18 at = ud(unwrap(decay) ** _timePassed);
        UD60x18 wLastRate = ud(_lastRate);
        UD60x18 wTargetRate = ud(_targetRate);

        return at.mul(wLastRate) + (ONE.sub(at).mul(wTargetRate)); // No need to check overflow on solidity >=0.8.0
    }

    /**
     * @custom:retomar Me quede haciendo los limites de los parametros
     * time :: 1_099_511_627_775 ~ 1.1e12
     * at   ::
     */

    // type(uint).max = ~115.79e75
    // 05/01/24 -> 0x61d4df80
    ///@custom:lim-time Vamos a limitar el tiempo a un uint40
    // 05/01/2222 -> 0x1cfa82480 (uint40)
    /* *************************************************************************************************************************************/
    /* ** Internal  Params Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/
    /**
     * @custom:sec
     * Aca hay que poner checks de sueguridad, por ejemplo, al momento de que pasamos los datos de uint -> a UD60x18
     */
    function _setFormulaParams(FormulaParams calldata _params) internal {
        UD60x18 _dc = _decayBounds(_params.decay);
        UD60x18 _mxfl = _maxFlowBound(_params.maxFlow);
        UD60x18 _msk = _minRatioBounds(_params.minStakeRatio);

        decay = _dc;
        maxFlow = _mxfl;
        minStakeRatio = _msk;

        emit FormulaParamsChanged(_dc /*, drop.mulu(1e18),*/, _mxfl, _msk);
    }

    // 93077

    enum Bound {
        Upper,
        Lower
    }

    error VAR_EXCEEDS_BOUNDS(
        Bound _boundExceeded,
        UD60x18 _maxVal,
        UD60x18 _valCalc
    );

     /**
     * Limitaciones del maxFlow (min,max)
     * El flow limite tiene que ser 333 dias de flow 
     * min : por lo menos 1 unidad  
     * max : tiene que poderse dar al menos por 333 dias el flow
     * @param _maxFlow es el ratio que se manda por segundo, por lo tanto, el maximo tiene poderse mandar por lo menos por la minima cantiad de dias
      1. max : [type(uint).max / 1e18 (para convertirlo en UD60x18)]/ 0x5250a80
     */
    function _maxFlowBound(
        uint176 _maxFlow
    ) internal view returns (UD60x18 _mxflw) {
        _mxflw = ud((_maxFlow * 1e18) + 1);
        if (MIN_FLOW_BOUND > _mxflw)
            revert VAR_EXCEEDS_BOUNDS(Bound.Lower, MIN_FLOW_BOUND, _mxflw);
        else if (MAX_FLOW < _mxflw)
            revert VAR_EXCEEDS_BOUNDS(Bound.Upper, MAX_FLOW, _mxflw);
    }
    
    function _decayBounds(uint _decay) internal view returns (UD60x18 _dc) {
        _dc = ud((_decay * 1e18) + 1);
    }

    function _minRatioBounds(uint _ratio) internal view returns (UD60x18 _mrt) {
        _mrt = ud((_ratio * 1e15) + 1);
        if (MIN_STAKE_RATIO > _mrt)
            revert VAR_EXCEEDS_BOUNDS(Bound.Lower, MIN_STAKE_RATIO, _mrt);
        else if (MAX_STAKE_RATIO < _mrt)
            revert VAR_EXCEEDS_BOUNDS(Bound.Upper, MAX_STAKE_RATIO, _mrt);
    }

    function _setMaxFlow(uint176 _maxFlow) internal {
        maxFlow = _maxFlowBound(_maxFlow);
        emit FormulaParamsChanged(
            decay /*, drop.mulu(1e18),*/,
            convert(_maxFlow),
            minStakeRatio
        );
    }

    function _setDecay(uint256 _decay) internal {
        decay = _decayBounds(_decay);
        emit FormulaParamsChanged(
            convert(_decay) /*, drop.mulu(1e18),*/,
            maxFlow,
            minStakeRatio
        );
    }

    /**
     *
     * @param _minStakeRatio must be between  10 && 15100
     * Wich refers to 0.01% && 15%
     */
    function _setMinStakeRatio(uint256 _minStakeRatio) internal {
        UD60x18 _mrtio = _minRatioBounds(_minStakeRatio);
        minStakeRatio = _mrtio;
        emit FormulaParamsChanged(decay /*, drop,*/, maxFlow, _mrtio);
    }
}

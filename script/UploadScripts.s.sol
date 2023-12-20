
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {Controller, MimeInit, PoolInit, OsmoticParams, OsmoticPool, OwnableProjectList, MimeToken, MimeTokenFactory, BeaconProxy, UpgradeableBeacon} from "../src/refactor/Controller.sol";

import {ProjectRegistry} from "../src/refactor/projects/ProjectRegistry.sol";

abstract contract DeploySystem is Script {
    MimeInit mime_initData;
    PoolInit pool_initData;
    OsmoticParams formula_params;

    UpgradeableBeacon beacon_controller;
    BeaconProxy proxy_controller;
    Controller impl_controller;

    UpgradeableBeacon beacon_pool;
    BeaconProxy proxy_pool;
    OsmoticPool impl_pool;

    UpgradeableBeacon beacon_mimeFactory;
    BeaconProxy proxy_mimeFactory;
    MimeTokenFactory impl_mimeFactory;
    MimeToken impl_mime;

    UpgradeableBeacon beacon_registry;
    BeaconProxy proxy_registry;
    ProjectRegistry impl_registry;

    constructor(
        MimeInit memory _mimeInit,
        PoolInit memory _poolInit,
        OsmoticParams memory _formulaParams
    ) {
        mime_initData = _mimeInit;
        pool_initData = _poolInit;
        formula_params = _formulaParams;
    }

    /**
      ---------------------------------------------
                    GETTER_FUNCTIONS
      ---------------------------------------------
     */
    function getStructParams()
        external
        view
        returns (MimeInit memory, PoolInit memory, OsmoticParams memory)
    {
        return (mime_initData, pool_initData, formula_params);
    }

    function getController()
        external
        view
        returns (UpgradeableBeacon, BeaconProxy, Controller)
    {
        return (beacon_controller, proxy_controller, impl_controller);
    }

    function getPool()
        external
        view
        returns (UpgradeableBeacon, BeaconProxy, OsmoticPool)
    {
        return (beacon_pool, proxy_pool, impl_pool);
    }

    function getMime()
        external
        view
        returns (UpgradeableBeacon, BeaconProxy, MimeTokenFactory, MimeToken)
    {
        return (
            beacon_mimeFactory,
            proxy_mimeFactory,
            impl_mimeFactory,
            impl_mime
        );
    }

    function getRegistry()
        external
        view
        returns (UpgradeableBeacon, BeaconProxy, ProjectRegistry)
    {
        return (beacon_registry, proxy_registry, impl_registry);
    }

    /**
      ---------------------------------------------
                    CREATE_FUNCTIONS
      ---------------------------------------------
     */

    /**
     * @custom:beacon-owners
     * _owners[0] := Owner of the mimefactory (beacon)
     * _owners[1] := Owner of the registry (beacon)
     * _owners[2] := Owner of the controller (beacon)
     *
     */
    function createController(
        address[3] memory _owners
    ) external returns (address) {
        impl_pool = new OsmoticPool();

        address[3] memory _registryAddrs = _createRegistry(_owners[0]);
        address[4] memory _mimeAddrs = _createMimeFactory(_owners[1]);

        bytes memory _controllerInit = _encodeControllerInit(
            [address(impl_pool), _registryAddrs[0], _mimeAddrs[0]]
        );

        address[3] memory _controllerAddr = _createController(
            _owners[2],
            _controllerInit
        );

        return _controllerAddr[0];
    }

    /**
      ---------------------------------------------
                    HELPER_FUNCTIONS
      ---------------------------------------------
     */
    function _createController(
        address _cOwner,
        bytes memory _initController
    ) internal returns (address[3] memory _addr) {
        impl_controller = new Controller();

        beacon_controller = new UpgradeableBeacon(
            address(impl_controller),
            _cOwner
        );

        proxy_controller = new BeaconProxy(
            address(beacon_controller),
            _initController
        );

        _addr[0] = address(proxy_controller);
        _addr[1] = address(beacon_controller);
        _addr[2] = address(impl_controller);
    }

    function _createMimeFactory(
        address _factoryOwn
    ) internal returns (address[4] memory _addr) {
        impl_mime = new MimeToken();

        impl_mimeFactory = new MimeTokenFactory(address(impl_mime));
        beacon_mimeFactory = new UpgradeableBeacon(
            address(impl_mimeFactory),
            _factoryOwn
        );

        proxy_mimeFactory = new BeaconProxy(address(beacon_mimeFactory), "");

        _addr[0] = address(proxy_mimeFactory);
        _addr[1] = address(beacon_mimeFactory);
        _addr[2] = address(impl_mimeFactory);
        _addr[3] = address(impl_mime);
    }

    function _createRegistry(
        address _Ownr
    ) internal returns (address[3] memory _regAddr) {
        impl_registry = new ProjectRegistry(1);
        beacon_registry = new UpgradeableBeacon(address(impl_registry), _Ownr);
        proxy_registry = new BeaconProxy(address(beacon_registry), "");

        _regAddr[0] = address(proxy_registry);
        _regAddr[1] = address(beacon_registry);
        _regAddr[2] = address(impl_registry);
    }

    function _encodeControllerInit(
        address[3] memory _addr
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                _addr[0],
                _addr[1],
                _addr[2]
            );
    }
}

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UUPSUpgradeable, ERC1967Utils} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
// import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

// import {MimeToken, MimeTokenFactory} from "../librerias/mime/MimeTokenFactory.sol";

// import {OwnableProjectList} from "./projects/OwnableProjectList.sol";
// ///@custom:retocar
// // import {Pool,Params} from "./Pool.sol";

// struct MimeInit {
//     string name;
//     string symbol;
//     bytes32 merkleRoot;
//     uint currentTimestamp;
//     uint roundDuration;
// }

// struct PoolInit {
//     address cfa;
//     address controller;
//     address funding;
//     address mime;
//     address list;
//     Params params;
// }

// contract Controller is
//     Initializable,
//     OwnableUpgradeable,
//     PausableUpgradeable,
//     UUPSUpgradeable
// {
 
//     //-----------------------------------//
//     //              EVENTS               //
//     //-----------------------------------//
//     event MimeTokenCreated(address indexed token);
//     event PoolCreated(address indexed pool);
//     event ProjectListCreated(address indexed list);

    

//     //-----------------------------------------------//
//     //                  STORAGE                      //
//     //-----------------------------------------------//
//     /**
//      * @custom:default In case roundDuration passed as crating the pool, the minimum will be used
//      *
//      * @custom:recommendation Using ~ 1 month as a roundDuration is a good approach
//      */
//     uint constant MIN_ROUND_DURATION = 7 days;
    

//     address public projectRegistry;
//     address public mimeTokenFactory;
//     UpgradeableBeacon public beacon;
    

//     /**
//      * @dev Just in case we need those storage slots and to avoid getting clashes on future versions
//      */
//     uint[22] internal __storageGap;

//     // mapping(address => bool) public isPool;
//     // mapping(address => bool) public isList;
//     // mapping(address => bool) public isToken;
//     /**
//      * @custom:refactor
//      * Instead of using 3 different mappings to we pack all information inside one due a better use of the storage
//      */
//     struct AddressInfo {
//         bool isPool;
//         bool isList;
//         bool isToken;
//         bool isMime;
//     }

//     mapping(address => AddressInfo) addressInfo;

//     //---------------------------------------------------------//
//     //                      INITIALIZE                         //
//     //---------------------------------------------------------//

//     function initialize(
//         address _Pool,
//         address _projectRegistry,
//         address _mimeTokenFactory
//     ) public initializer {
//         __Pausable_init();
//         __Ownable_init(msg.sender);
//         __UUPSUpgradeable_init();

//         beacon = new UpgradeableBeacon(_Pool, msg.sender);
//         // We transfer the ownership of the beacon to the deployer

//         projectRegistry = _projectRegistry;
//         mimeTokenFactory = _mimeTokenFactory;

//         // We set the registry as the default list
//         addressInfo[_projectRegistry].isList = true;
//     }
//     //--------------------------------------------------------------------//
//     //                          Getter-functions                          //
//     //--------------------------------------------------------------------//

//     /**
//      * @dev Retruns if `_isPool` is registered as a pool
//      */
//     function isPool(address _isPool) external view returns (bool) {
//         return addressInfo[_isPool].isPool;
//     }

//     /**
//      * @dev Retruns if `_isList` is registered as a list
//      */
//     function isList(address _isList) external view returns (bool) {
//         return addressInfo[_isList].isList;
//     }

//     /**
//      * @dev Retruns if `_isList` is registered as a list
//      */
//     function isToken(address _isList) external view returns (bool) {
//         return addressInfo[_isList].isToken;
//     }


//     function getAddressInfo(
//         address _address
//     ) external view returns (AddressInfo memory) {
//         return addressInfo[_address];
//     }
    
//     function encodePoolInitLoad(PoolInit memory _init) external view returns (bytes memory) {
//         return _encodePoolInit(_init);
//     }
    
//     function encodeMimeInitLoad(MimeInit memory _init) external view returns (bytes memory) {
//         return _encodeMimeInitLoad(_init);
//     }
//     //---------------------------------------------------------//
//     //                    Pausable-functions                   //
//     //---------------------------------------------------------//

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     //-------------------------------------------------//
//     //              UpgradeProxy-functions             //
//     //-------------------------------------------------//

    

//     function implementation() external view returns (address) {
//         return ERC1967Utils.getImplementation();
//     }

//     function PoolImplementation() external view returns (address) {
//         return beacon.implementation();
//     }

//     function _authorizeUpgrade(
//         address newImplementation
//     ) internal override onlyOwner {}
   
//     //-------------------------------------------------//
//     //                  List-function                  //
//     //-------------------------------------------------//
    

//     function createProjectList(
//         string calldata _name,
//         uint[] memory _idsToAdd
//     ) external whenNotPaused returns (address list_) {
//         return _createProjectList(_name, _idsToAdd);
//     }

//     //----------------------------------------------------------//
//     //                     Pool-functions                       //
//     //----------------------------------------------------------//

//     function createPool(
//         PoolInit calldata _initPool
//     ) external virtual whenNotPaused returns (address pool_) {
//         bytes memory _initPoolData = _encodePoolInit(_initPool);
//         return _createPool(_initPoolData);
//     }

//     function createPool(
//         bytes calldata _initPayload
//     ) external virtual whenNotPaused returns (address pool_) {
//         return _createPool(_initPayload);
//     }
//     //--------------------------------------------------------------------//
//     //                      MIMETkn-functions                             //
//     //--------------------------------------------------------------------//

//     function createMimeToken(
//         bytes calldata _initPayload
//     ) external virtual whenNotPaused returns (address token_) {
//         return _createMime(_initPayload);
//     }

//     function createMimeToken(
//         MimeInit calldata _init
//     ) external virtual whenNotPaused returns (address token_) {
//         bytes memory _initData = _encodeMimeInitLoad(_init);
//         return _createMime(_initData);
//     }

//     //----------------------------------------------------------//
//     //                     Creation-functions                   //
//     //----------------------------------------------------------//
    

//     function completeBuild(
//         string calldata _name,
//         uint[] memory _idsToAdd,
//         MimeInit memory _initMime,
//         PoolInit memory _initPool
//     ) external virtual whenNotPaused returns (address[3] memory _rAddresses) {
//         address list_ = _createProjectList(_name, _idsToAdd);
//         address mime_;
//         address pool_;
//         {
//             bytes memory _initLoad = _encodeMimeInitLoad(_initMime);
//             mime_ = _createMime(_initLoad);
//         }
//         {
//             _initPool.list = list_;
//             _initPool.mime = mime_;
//             bytes memory _initLoad = _encodePoolInit(_initPool);
//             pool_ = _createPool(_initLoad);
//         }
//         _rAddresses[0] = list_;
//         _rAddresses[1] = mime_;
//         _rAddresses[2] = pool_;
//     }

//     //-------------------------------------------------//
//     //                 Internal-function               //
//     //-------------------------------------------------//
   
//     function _encodePoolInit(
//         PoolInit memory _init
//     ) internal view returns (bytes memory) {
//         _init.controller=address(this);
//         return
//             abi.encodeWithSignature(
//                 "initialize(address,address,address,address,address,(uint256,uint256,uint256,uint256))",
//                 _init.cfa,
//                 _init.controller,
//                 _init.funding,
//                 _init.mime,
//                 _init.list,
//                 _init.params
//             );
//     }
   
//     function _encodeMimeInitLoad(
//         MimeInit memory _init
//     ) internal view returns (bytes memory) {
//         _init.currentTimestamp = block.timestamp;
//         if (_init.roundDuration < MIN_ROUND_DURATION)
//             _init.roundDuration = MIN_ROUND_DURATION;
//         return
//             abi.encodeWithSignature(
//                 "initialize(string,string,bytes32,uint256,uint256)",
//                 _init.name,
//                 _init.symbol,
//                 _init.merkleRoot,
//                 _init.currentTimestamp,
//                 _init.roundDuration
//             );
//     }

//     function _createMime(
//         bytes memory _initPayload
//     ) internal returns (address t_) {
//         t_ = MimeTokenFactory(mimeTokenFactory).createMimeToken(_initPayload);

//         MimeToken(t_).transferOwnership(msg.sender);

//         addressInfo[t_].isToken = true;

//         emit MimeTokenCreated(t_);
//     }

//     function _createPool(
//         bytes memory _initPayload
//     ) internal returns (address pool_) {
//         pool_ = address(new BeaconProxy(address(beacon), _initPayload));

//         OwnableUpgradeable(pool_).transferOwnership(msg.sender);

//         addressInfo[pool_].isPool = true;

//         emit PoolCreated(pool_);
//     }

//     function _createProjectList(
//         string calldata _name,
//         uint[] memory _ids
//     ) internal returns (address list_) {
//         list_ = address(new OwnableProjectList(projectRegistry, _name));
//         uint l_ = _ids.length;
//         OwnableProjectList list = OwnableProjectList(list_);
//         /**
//          * @custom:nota if l_ == 0 only transfer ownership
//          */
//         if (l_ == 1) list.addProject(_ids[0]);
//         else list.addProjects(_ids);

//         list.transferOwnership(msg.sender);

//         addressInfo[list_].isList = true;
//         emit ProjectListCreated(list_);
//     }
// }

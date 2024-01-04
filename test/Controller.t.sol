// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../script/UploadScript.s.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WrpDeployment is DeploySystem {
    constructor(
        MimeInit memory _mimeInit,
        PoolInit memory _poolInit,
        OsmoticParams memory _formulaParams
    ) DeploySystem(_mimeInit, _poolInit, _formulaParams) {}
}

contract MFunding is ERC20 {
    constructor(string[2] memory _strs) ERC20(_strs[0], _strs[1]) {}

    function mint(uint amount, address _a) external {
        _mint(_a, amount);
    }

    function burn(uint amount, address _a) external {
        _burn(_a, amount);
    }
}

contract MCFA {
    constructor() {}
}
/**
 * @custom:coverage ~ 100% 22.12.23
 * forge test --mc ControllerTest -vvvv 
 */
contract ControllerTest is Test {
    WrpDeployment deployment;
    MCFA cfa;
    address[3] init_owners;

    function setUp() external {
        MimeInit memory _mimeInit;
        _mimeInit.name = "MIME_MOCK";
        _mimeInit.symbol = "mMIME";
        _mimeInit
            .merkleRoot = 0x659d9490a902c959e5229c5e585281e2bbd0f643256c8561526381fe82ef2ff0;
        _mimeInit.currentTimestamp = block.timestamp;
        _mimeInit.roundDuration = 28 days;

        PoolInit memory _poolInit;
        _poolInit.cfa = address(new MCFA());
        _poolInit.funding = address(new MFunding(["STABLE_MOCK", "mSTB"]));

        OsmoticParams memory _p;
        init_owners=[makeAddr("OW1"),makeAddr("OW2"),makeAddr("OW3")];

        deployment = new WrpDeployment(_mimeInit, _poolInit, _p);
        deployment.createController(init_owners);

        {
            (, BeaconProxy _c, ) = deployment.getController();
            Controller c = Controller(address(_c));
            
            vm.expectRevert(); //reinited
            c.initialize(address(1),address(2),address(3));

            address _prevOw=c.owner();
            address _tOw=makeAddr('TRS_Owner');
            vm.prank(_prevOw);
            c.transferOwnership(_tOw);

            vm.prank(_prevOw);
            vm.expectRevert(); //not_owner
            c.transferOwnership(_tOw);

            vm.prank(_tOw);
            c.transferOwnership(_prevOw);

        }
    }

    // forge test --mt test_createController -vvvv
    function test_createController(address[3] memory _ad) external {
        vm.assume(_ad[0] != address(0));
        vm.assume(_ad[1] != address(0));
        vm.assume(_ad[2] != address(0));

        deployment.createController(_ad);
        _deploymentGetters();
    }

    // forge test --mt test_createProjectlist -vvvv
    function test_createProjectlist(
        address[3] memory _ad,
        uint8 _amProjects
    ) external {
        {
            vm.assume(_ad[0] != address(0));
            vm.assume(_ad[1] != address(0));
            vm.assume(_ad[2] != address(0));
            vm.assume(_amProjects > 0);
        }
        deployment.createController(_ad);

        uint[] memory _ids = _registerIds(_amProjects);

        string memory _l1 = "LIST#1";
        string memory _l2 = "LIST#2";

        uint[] memory _u = new uint[](0);
        address _s1 = makeAddr("Sender1");
        address _s2 = makeAddr("Sender2");

        (, BeaconProxy _p, ) = deployment.getController();
        Controller c = Controller(address(_p));
        vm.startPrank(_s1);
        c.createProjectList(_l1, _u);

        vm.startPrank(_s2);
        c.createProjectList(_l2, _ids);
    }

    // forge test --mt test_completeBuild -vvvv
    function test_completeBuild(
        address[3] memory _ad,
        uint8 _amProjects
    ) external {
        {
            vm.assume(_ad[0] != address(0));
            vm.assume(_ad[1] != address(0));
            vm.assume(_ad[2] != address(0));
            vm.assume(_amProjects > 0);
        }
        deployment.createController(_ad);
        string memory _l1 = "LIST#1";

        uint[] memory _ids = _registerIds(_amProjects);
        MimeInit memory _initMime;
        PoolInit memory _initPool;
        (_initMime, _initPool, ) = deployment.getStructParams();

        (, BeaconProxy _p, ) = deployment.getController();
        Controller c = Controller(address(_p));
        vm.prank(c.owner());
        c.pause();
        vm.expectRevert(); // Pausa2
        c.completeBuild(_l1, _ids, _initMime, _initPool);

        vm.prank(c.owner());
        c.unpause();

        address[3] memory _addr = c.completeBuild(
            _l1,
            _ids,
            _initMime,
            _initPool
        );

        assertTrue(c.isList(_addr[0]));
        assertTrue(c.isToken(_addr[1]));
        assertTrue(c.isPool(_addr[2]));
    }

    // forge test --mt test_createMime -vvvv

    function test_createMime(address[3] memory _ad) external {
        {
            vm.assume(_ad[0] != address(0));
            vm.assume(_ad[1] != address(0));
            vm.assume(_ad[2] != address(0));
            // vm.assume(_amProjects > 0);
        }
        deployment.createController(_ad);
        (, BeaconProxy _p, ) = deployment.getController();
        Controller c = Controller(address(_p));

        MimeInit memory _initMime;
        (_initMime, , ) = deployment.getStructParams();
        bytes memory _encodedInit=c.encodeMimeInitLoad(_initMime);
        vm.prank(c.owner());
        c.pause();

        vm.expectRevert(); //Paused
        c.createMimeToken(_initMime);
        vm.expectRevert(); //Paused
        c.createMimeToken(_encodedInit);

        vm.prank(c.owner());
        c.unpause();


        c.createMimeToken(_initMime);
        c.createMimeToken(_encodedInit);


    }
    // forge test --mt test_createPool -vvvv
    function test_createPool(address[3] memory _ad) external {
        {
            vm.assume(_ad[0] != address(0));
            vm.assume(_ad[1] != address(0));
            vm.assume(_ad[2] != address(0));
            // vm.assume(_amProjects > 0);
        }
        deployment.createController(_ad);
        (, BeaconProxy _p, ) = deployment.getController();
        Controller c = Controller(address(_p));
        MimeInit memory _initMime;
        PoolInit memory _initPool;
        {
            (_initMime, _initPool, ) = deployment.getStructParams();
        }
        
        address _s1 = makeAddr("Sender1");
        string memory _l1 = "LIST#1";
        uint[] memory _u ;


        vm.startPrank(_s1);
        address _list=c.createProjectList(_l1, _u);
       
        address _mime= c.createMimeToken(_initMime);

        _initPool.list=_list;
        _initPool.mime=_mime;

        bytes memory _iPool=c.encodePoolInitLoad(_initPool);

        vm.prank(c.owner());
        c.pause();
        {
            vm.expectRevert(); //Paused
            c.createOsmoticPool(_initPool);
            vm.expectRevert(); //Paused
            c.createOsmoticPool(_iPool);

        }

        vm.prank(c.owner());
        c.unpause();


        address p1=c.createOsmoticPool(_initPool);
        address p2=c.createOsmoticPool(_iPool);

        c.getAddressInfo(p1);
        c.getAddressInfo(p2);
    }

    function _registerIds(uint _am) internal returns (uint[] memory) {
        (, BeaconProxy _p, ) = deployment.getRegistry();
        ProjectRegistry r = ProjectRegistry(address(_p));
        uint[] memory _ids = new uint[](_am);
        if (_am == 1) {
            address a = makeAddr("a");
            _ids[0] = r.registerProject(a, "");
        } else {
            uint i = 0;
            for (; i < _am; ) {
                _ids[i] = r.registerProject(makeAddr(Strings.toString(i)), "");
                unchecked {
                    ++i;
                }
            }
        }
        vm.prank(r.owner());

        return _ids;
    }

    /**
     * @custom:testear :
      ->[ok] isPool()
      ->[ok] isList()
      ->[ok] isToken()
      ->[ok] getAddressInfo()
      ->[ok] pause()                    [owner]   
      ->[ok] unpause()                  [owner]
      ->[ok] implementation()           
      ->[ok] osmoticPoolImplementation()
      ->[ok] encodePoolInitLoad()
      ->[ok] encodeMimeInitLoad()

      ->[ok] createProjectList()        [not-paused]
      ->[ok] createOsmoticPool()        [not-paused]{bytes}
      ->[ok] createOsmoticPool()        [not-paused]{raw-data}
      ->[ok] createMimeToken()          [not-paused]{bytes}
      ->[ok] createMimeToken()          [not-paused]{raw-data}
      ->[ok] completeBuild()            [not-paused]{raw-data}

     */

    function _deploymentGetters() internal view {
        deployment.getStructParams();
        deployment.getPool();
        deployment.getMime();
        deployment.getRegistry();
        (, BeaconProxy _p, ) = deployment.getController();
        Controller c = Controller(address(_p));
        c.implementation();
        c.osmoticPoolImplementation();
    }
}

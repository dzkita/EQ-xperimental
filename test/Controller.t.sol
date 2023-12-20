// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../script/UploadScript.s.sol";
import "forge-std/Test.sol";

contract WrpDeployment is DeploySystem {
    constructor(
        MimeInit memory _mimeInit,
        PoolInit memory _poolInit,
        OsmoticParams memory _formulaParams
    ) DeploySystem(_mimeInit, _poolInit, _formulaParams) {}
}
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

contract ControllerTest is Test {
    WrpDeployment deployment;
    MCFA cfa;

    function setUp() external {
        MimeInit memory _mimeInit;
        _mimeInit.name = "MIME_MOCK";
        _mimeInit.symbol = "mMIME";
        _mimeInit
            .merkleRoot = 0x659d9490a902c959e5229c5e585281e2bbd0f643256c8561526381fe82ef2ff0;
        _mimeInit.currentTimestamp = block.timestamp;
        _mimeInit.roundDuration = 28 days;

        PoolInit memory _poolInit;
        _poolInit.cfa= address(new MCFA());
        _poolInit.funding= address(new MFunding(['STABLE_MOCK','mSTB']));

        OsmoticParams memory _p;

        deployment= new WrpDeployment(_mimeInit,_poolInit,_p);


    }
}


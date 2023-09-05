// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @author  0xAurelou
 * @title   ERC20 LayerZero
 * @dev     Do not use in production this is for research purposes only
 * @notice  ERC20 using LayerZero contract
 */

contract LzERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply)
        ERC20(_name, _symbol)
    {
        _mint(_msgSender(), _initialSupply);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

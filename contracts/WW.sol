// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldWarToken is ERC20, Ownable {
    uint256 public taxRate = 1; // 1% on all transfers

    address public reserveWallet;
    address public devWallet;
    address public donationWallet;

    mapping(address => bool) private _isExcludedFromTax;
    address public router;

    constructor(address _reserve, address _dev, address _donation) ERC20("World War Token", "WW") Ownable(msg.sender) {
        uint256 totalSupply = 100_000_000 * 10 ** decimals();

        uint256 devAmount = (totalSupply * 15) / 100;
        uint256 reserveAmount = totalSupply - devAmount;

        reserveWallet = _reserve;
        devWallet = _dev;
        donationWallet = _donation;

        _mint(devWallet, devAmount);
        _mint(reserveWallet, reserveAmount);

        // Exclude from tax
        _isExcludedFromTax[msg.sender] = true;
        _isExcludedFromTax[reserveWallet] = true;
        _isExcludedFromTax[devWallet] = true;
        _isExcludedFromTax[donationWallet] = true;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function excludeFromTax(address account, bool excluded) external onlyOwner {
        _isExcludedFromTax[account] = excluded;
    }

    function _handleTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromTax[sender] || _isExcludedFromTax[recipient]) {
            return amount;
        }
        uint256 taxAmount = (amount * taxRate) / 100;
        if (taxAmount > 0) {
            super._transfer(sender, donationWallet, taxAmount);
        }
        return amount - taxAmount;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 finalAmount = _handleTax(msg.sender, recipient, amount);
        return super.transfer(recipient, finalAmount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 finalAmount = _handleTax(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - (amount));
        return super.transferFrom(sender, recipient, finalAmount);
    }
}
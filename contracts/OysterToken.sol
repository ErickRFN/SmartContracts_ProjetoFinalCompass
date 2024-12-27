// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract OysterToken is ERC20, Ownable, ERC20Permit {
    OysterVault public vault;
    mapping(address => bool) public validMusicContracts;

    event validatedMusicContract(address indexed _address, bool valid);
    event WeiRefunded(address indexed to, uint256 gweiAmount);

    modifier onlyValidMusicContract() {
        require(validMusicContracts[msg.sender], "This function can only be called by the valid MusicContract address");
        _;
    }

    constructor(address initialOwner) 
        ERC20("OysterToken", "OST") 
        Ownable(initialOwner) 
        ERC20Permit("OysterToken") 
    {}

    // Função para configurar o endereço do Vault após a implantação
    function setVault(OysterVault _vault) external onlyOwner {
        require(address(vault) == address(0), "Vault already set");
        require(address(vault) != address(0), "Invalid vault address");
        vault = _vault;
    }

    // Mint para o Vault
    function mintToVault(uint256 amount) external onlyOwner {
        require(address(vault) != address(0), "Vault address not set");
        _mint(address(vault), amount);
    }

    // Adicionar o endereço e validar de um contract de música
    function validateMusicContracts(address addressMusicContract) external onlyOwner returns (bool) {
        validMusicContracts[addressMusicContract] = true;

        emit validatedMusicContract(addressMusicContract, true);
        return true;
    }

    // Função de comprar 100 tokens para o contrato de musica
    function buy100OSTToMusicContract() external payable onlyValidMusicContract returns (bool) {
        require(msg.value >= 5200000, "Insufficient Wei sent to buy tokens");

        uint256 tokensToBuy = 100;
        uint256 gweiRequired = 5000000;
        uint256 remainingWei = msg.value - gweiRequired;

        require(vault.viewTokensVault() >= tokensToBuy, "Not enough tokens in OysterToken contract");

        vault.sendToken(msg.sender, tokensToBuy);

        uint256 remainingEther = remainingWei / 1e18;
        payable(msg.sender).transfer(remainingEther);

        emit WeiRefunded(msg.sender, msg.value);
        return true;
    }



}

contract OysterVault is Ownable {
    IERC20 public oysterToken;

    event TokensDistributed(address indexed to, uint256 amount);

    modifier onlyOysterToken() {
        require(msg.sender == address(oysterToken), "This function can only be called by the oysterToken address");
        _;
    }

    constructor(IERC20 _oysterToken, address initialOwner) Ownable(initialOwner) {
        oysterToken = _oysterToken;
    }

    function sendToken(address to, uint256 amount) external onlyOysterToken returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(
            oysterToken.balanceOf(address(this)) >= amount,
            "Vault does not have enough tokens"
        );
        require(
            oysterToken.transfer(to, amount),
            "Token transfer failed"
        );

        emit TokensDistributed(to, amount);
        return true;
    }

    function viewTokensVault() external view returns (uint256) {
        return oysterToken.balanceOf(address(this));
    }
}
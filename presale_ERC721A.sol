// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract presaleSM is ERC721A, Ownable {
    using Strings for uint256;

    string baseURI;
    string notRevealedURI;

    bytes32 public root;

    uint256 public maxSupply = 1000;
    uint256 public whitelistSupply = 500;
    uint256 public mintPrice = 0.004 ether;
    uint256 public MaxMintWhitelist = 2;
    uint256 public MaxmintPublic = 1;

    bool public revealed = false;

    enum Phase {
        locked,
        privateSale,
        publicSale
    }

    Phase public currentPhase = Phase.locked;

    mapping(address => uint256) public WhitelistWalletMints;
    mapping(address => uint256) public PublicWalletMints;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedURI,
        string memory _revealedURI,
        bytes32 _root
    ) ERC721A(_name, _symbol) {
        setNotRevealedURI(_notRevealedURI);
        setBaseURI(_revealedURI);
        root = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setReveal() external onlyOwner {
        revealed = !revealed;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setWhitelistSupply(uint256 _whitelistSupply) external onlyOwner {
        whitelistSupply = _whitelistSupply;
    }

    function setMaxmintWhitelist(uint256 _maxmintAmount) external onlyOwner {
        MaxMintWhitelist = _maxmintAmount;
    }

    function setMaxmintPublic(uint256 _maxmintAmount) external onlyOwner {
        MaxmintPublic = _maxmintAmount;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPhase(Phase _phase) external onlyOwner {
        currentPhase = _phase;
    }

    function ownerMint(uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Sold Out");
        require(_amount > 0, "Enter a valid amount");
        _safeMint(msg.sender, _amount);
    }

    function privateMint(uint256 _amount, bytes32[] memory proof)
        external
        payable
    {
        require(currentPhase == Phase.privateSale, "Private sale not enabled");
        require(
            _isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            "You are not whitelisted"
        );
        require(
            WhitelistWalletMints[msg.sender] + _amount <= MaxMintWhitelist,
            "Exceeds max allocation per whitelist user"
        );
        require(msg.value >= mintPrice * _amount, "Wrong value");
        require(totalSupply() + _amount <= maxSupply, "Sold Out");

        WhitelistWalletMints[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable {
        require(currentPhase == Phase.publicSale, "Public sale not enabled");
        require(
            PublicWalletMints[msg.sender] + _amount <= MaxmintPublic,
            "Exceeds max allocation per user"
        );
        require(msg.value >= mintPrice * _amount, "Wrong value");
        require(totalSupply() + _amount <= maxSupply, "Sold Out");

        PublicWalletMints[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function _isValid(bytes32[] memory proof, bytes32 leaf)
        private
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdrawFunds(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
    }
}

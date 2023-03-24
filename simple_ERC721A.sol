// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DrunkiesNFT is ERC721A, Ownable {
    using Strings for uint256;

    string baseURI;

    uint256 public maxSupply = 1000;
    uint256 public mintPrice = 0.004 ether;

    bool public isMintEnabled;

    mapping(address => uint256) public WalletMints;

    constructor(string memory _uri) ERC721A("Drunkies", "drnk") {
        setBaseURI(_uri);
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

    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function ownerMint(uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Sold Out");
        require(_amount > 0, "Enter a valid amount");
        _safeMint(msg.sender, _amount);
    }

    function mint() external payable {
        require(isMintEnabled, "Minting not enabled");
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        require(WalletMints[msg.sender] < 1, "Exceeds max per wallet");
        require(msg.value >= mintPrice, "Wrong value");
        require(totalSupply() < maxSupply, "Sold Out");

        WalletMints[msg.sender]++;
        _safeMint(msg.sender, 1);
    }

    function withdrawFunds(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
    }
}
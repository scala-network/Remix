// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
// import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
// import "github.com/provable-things/ethereum-api/provableAPI.sol";
// import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "hardhat/console.sol";

contract wXLA is Initializable, 
ERC20Upgradeable, 
ERC20BurnableUpgradeable, 
PausableUpgradeable, 
AccessControlUpgradeable, 
ERC20PermitUpgradeable, UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    // constructor() {
    //     _disableInitializers();
    // }
    
    function initialize(uint8 _currentVersion) initializer public {
        CURRENT_VERSION=_currentVersion;
        __ERC20_init(name(), symbol());
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name());
        __UUPSUpgradeable_init();
        // __PaymentSplitter_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
    }

    /**
     * @dev Upgrade coin function
     */    
    uint256 internal CURRENT_VERSION;
    function getCurrentVersion() public view returns(uint256) {
        return CURRENT_VERSION;
    }

    /**
     * Token Information
     **/
    function name() public view virtual override returns (string memory) {
        return "XLA ERC20";
    }
   
    function symbol() public view virtual override returns (string memory) {
        return "wXLA";
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
       // _mint(_msgSender(), amount * 0.01);
       _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // mapping (address => bool) internal blackLists;
    // function isBlacklists(address user) view external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    //     require(!blackLists[user], "Address is blacklisted");
    //     return false;
    // }

    // function addBlackList (address user)  external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     blackLists[user] = true;
    //     emit AddedBlackList(user);
    // }

    // function removeBlackList (address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     blackLists[user] = false;
    //     emit RemovedBlackList(user);
    // }

    // event AddedBlackList(address _user);
    // event RemovedBlackList(address _user);

  /**
    * Swap
    */
    struct XLASwap {
        bytes32 digest;
        address account;
        uint256 amount;
        bool toSwap;
        uint256 height;
    }

    event XLASwapCreated(XLASwap indexed data);

    mapping (bytes32 => XLASwap) internal XLASwapData;
    bytes32[] internal XLASwapLists;

    function xlaSetSalt(uint8 i, string calldata salt) public onlyRole(MINTER_ROLE) {
        XlaSalt[i] = keccak256(abi.encodePacked(salt));
    }

    function xlaGetSalt(uint8 i) view public onlyRole(MINTER_ROLE)  returns(bytes32) {
        require(XlaSalt[i] != bytes32(0), "Invalid hash pointer");
        return XlaSalt[i];
    }

    function xlaMint(address owner,bytes32 ipfsHash, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable {
        require(block.timestamp <= deadline, "XLASwap: expired deadline");
        require(owner != address(0) && hasRole(MINTER_ROLE, owner), "XLASwap: Invalid owner");
        uint256 max = (2**256 - 1);
        require(0 < amount && max > amount, "XLASwap: Invalid swap amount");  
        require(ipfsHash != bytes32(0) && XLASwapData[ipfsHash].account == address(0),"XLASwap: Invalid ipfshash");
        address spender = msg.sender;
        require(spender != address(0),"XLASwap: Invalid spender");
        require(XlaSalt[1] != bytes32(0),"XLASwap: Salt does not exists");
        uint256 nonce = nonces(spender);
        bytes32 structHash = keccak256(abi.encode(XlaSalt[1], owner, spender, true, ipfsHash, amount, deadline, nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        bytes32 es = ECDSAUpgradeable.toEthSignedMessageHash(hash);
        address signer = ECDSAUpgradeable.recover(es, v, r, s);
        require(signer == owner, "XLASwap: invalid signature");
        _mint(spender, amount);
        _useNonce(spender);
        XLASwapData[ipfsHash] = XLASwap(ipfsHash, spender, amount, true, block.number);
        emit XLASwapCreated(XLASwapData[ipfsHash]);
    }

    function xlaMintGasless(address spender,bytes32 ipfsHash, uint256 amount) external payable  onlyRole(MINTER_ROLE) {
        uint256 max = (2**256 - 1);
        require(0 < amount && max > amount, "XLASwap: Invalid swap amount");  
        require(ipfsHash != bytes32(0) && XLASwapData[ipfsHash].account == address(0),"XLASwap: Invalid ipfshash");
        require(spender != address(0),"XLASwap: Invalid spender");
        _mint(spender, amount);
        _useNonce(spender);
        XLASwapData[ipfsHash] = XLASwap(ipfsHash, spender, amount, true, block.number);
        emit XLASwapCreated(XLASwapData[ipfsHash]);
    }

    function xlaBurnGasless(address spender, bytes32 ipfsHash, uint256 amount) external payable onlyRole(MINTER_ROLE){
        uint256 max = (2**256 - 1);
        require(ipfsHash != bytes32(0) && XLASwapData[ipfsHash].account == address(0),"XLASwap: Invalid ipfshash");
        require(spender != address(0),"XLASwap: Invalid spender");
        require(0 < amount && max > amount && balanceOf(spender) >= amount, "XLASwap: Invalid swap amount");  
        _burn(spender, amount);
        _spendAllowance(spender, msg.sender, amount);
        XLASwapData[ipfsHash] = XLASwap(ipfsHash, spender, amount, true, block.number);
        emit XLASwapCreated(XLASwapData[ipfsHash]);
    }


    function XLASwapById(bytes32 ipfsHash) public view returns(XLASwap memory) {
        require(XLASwapData[ipfsHash].account != address(0),"Invalid swap id");
        return XLASwapData[ipfsHash];
    }

    function XLASwapTransactions(uint page)public view virtual returns(bytes32[] memory) {
        uint256 length = XLASwapLists.length;
        require(length > 0, "XLASwap: Empty swap transaction");
        uint256 start = page * 100;
        require(length > start, "XLASwap: Page is bigger than swap transaction length");
        uint256 end = start + 100;

        if(end > length) {
            end = length;
        }

        // require(end <= length, "XLASwap: End record is bigger than transaction length");

        bytes32[] memory swaps = new bytes32[](end-start);
        uint idx = 0;
        for (uint256 i=start; i < end;i++ ) {
            swaps[idx] = XLASwapLists[i];
            idx++;
        }
        return swaps;
    }
    mapping (uint8 => bytes32) private XlaSalt;
    // mapping (bytes32 => bool) internal XlaHashed;

}

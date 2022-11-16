// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable@4.8.0/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/proxy/utils/UUPSUpgradeable.sol";


contract Bep20_XLA is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    // struct RoleData {
    //     mapping(address => bool) members;
    //     bytes32 adminRole;
    // };
    // mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address public constant ADMIN_ADDRESS = 0xCD86F3688bFe20D0a77f05AE2CCFce58Ee4AeA4D;
    bool private _haveInit = false;
    uint256 intVers = 0;
    bool private _paused;
    mapping (address => bool) public isBlackListed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
        _paused = false;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        // if(!_isInitialized) {
        //     _isInitialized = true;
        //initialize();
        // }
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return account == ADMIN_ADDRESS;
    }

    function owner() public returns(address){
        return ADMIN_ADDRESS;
    }
    /**
     * @dev Upgrade coin function
     */    
    function initialize() initializer public {
        if(_haveInit == false) {
            _haveInit = true;
            __ERC20_init("XLA Test On Bep20", "Bep20_XLA");
            __ERC20Burnable_init();
            __Pausable_init();
            __AccessControl_init();
            __ERC20Permit_init("XLA Test On Bep20");
            __UUPSUpgradeable_init();
            // totalSupply = 0l;
        }
        _grantRole(DEFAULT_ADMIN_ROLE, ADMIN_ADDRESS);
        _grantRole(PAUSER_ROLE, ADMIN_ADDRESS);
        _grantRole(MINTER_ROLE, ADMIN_ADDRESS);
        _grantRole(BURNER_ROLE, ADMIN_ADDRESS);
        _grantRole(UPGRADER_ROLE, ADMIN_ADDRESS);
        _setupRole(DEFAULT_ADMIN_ROLE, ADMIN_ADDRESS);
        _setupRole(PAUSER_ROLE, ADMIN_ADDRESS);
        _setupRole(MINTER_ROLE, ADMIN_ADDRESS);
        _setupRole(BURNER_ROLE, ADMIN_ADDRESS);
        _setupRole(UPGRADER_ROLE, ADMIN_ADDRESS);
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return "XLA Test On Bep20";
    }

    function currentAddress() public view returns (address) {
        return _msgSender();
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return "Bep20_XLA";
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function burn(uint256 value) public onlyRole(BURNER_ROLE) override {
        // require(accountBalance >= value, "ERC20: burn amount exceeds balance");
        super._burn(msg.sender, value);
    }

     function burnFrom(address from, uint256 amount) public  override {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to burn"); 
        _burn(from, amount);
    }
 
    function mint(address to, uint256 amount) public{
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    function _pause() internal virtual whenNotPaused override {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }

    function _unpause() internal virtual whenPaused override{
        _paused = false;
        emit Unpaused(_msgSender());
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    { }

    function upgradeTo(address newImplementation, bytes memory) public {
         require(hasRole(UPGRADER_ROLE, _msgSender()), "must have upgrader role to upgrade");

    }

    function addBlackList (address _evilUser) public  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin to blacklist"); 
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
      
    }

    function removeBlackList (address _clearedUser) public  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin to remove blacklist"); 
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        require(!isBlackListed[from], "Sender address is blacklisted");
        require(!isBlackListed[to], "Receiver address is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }
    
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract wXLA is Initializable, 
ERC20Upgradeable, 
ERC20BurnableUpgradeable, 
PausableUpgradeable, 
// AccessControlUpgradeable, 
ERC20PermitUpgradeable, UUPSUpgradeable {

    bool public haveInit;
    bool private _paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

     function initialize(uint8 _currentVersion) initializer public onlyOwner {

        require(!haveInit, "ERC20: Contract already initialize");
        CURRENT_VERSION=_currentVersion;
        _paused = false;
        haveInit = true;
        __ERC20_init(name(), symbol());
        __ERC20Burnable_init();
        __Pausable_init();
        // __AccessControl_init();
        __ERC20Permit_init(name());
        __UUPSUpgradeable_init();
        // totalSupply = 0l;
    }

    /**
     * @dev Contract ownership
     */  
    function owner() public pure returns(address){
        return 0xCD86F3688bFe20D0a77f05AE2CCFce58Ee4AeA4D;
    }

    function isOwner(address account) public pure returns(bool){
        return owner() == account;
    }

    modifier onlyOwner {
        require(isOwner(msg.sender),"Only owner allowed");
        _;
    }

    function burner() public pure returns(address){
        return 0xCD86F3688bFe20D0a77f05AE2CCFce58Ee4AeA4D;
    }
   
    /**
     * @dev Upgrade coin function
     */    
    uint256 public CURRENT_VERSION;
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    { 
    }
    
    function updateTo(address newImplementation) external onlyOwner{

    }

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

    /**
     * Burning
     **/
    function burn(uint256 value) public onlyOwner override{
        require(0 < value, "ERC20: Amount request lower than 0");
        super._burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 amount) public  onlyOwner override{
        // require(0 < amount, "ERC20: Amount request lower than 0");
        require(balanceOf(from) < amount, "ERC20: burn amount exceeds balance");
        require(totalSupply() >= amount, "ERC20: burn amount exceeds totalSupply");
        super._burn(from, amount);
    }

     /**
     * Minting
     **/
    function mint(address to, uint256 amount) public onlyOwner{
        // require(0 >= amount, "ERC20: Amount request lower than 0");
        super._mint(to, amount);
    }

    /**
     * Pauseable methods.
     */
    function pause() public onlyOwner{
        _pause();
    }

    function _pause() internal virtual whenNotPaused onlyOwner override{
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner{
        _unpause();
    }

    function _unpause() internal virtual whenPaused onlyOwner override{
        _paused = false;
        emit Unpaused(msg.sender);
    }


    /**
    * Swap
    */
    mapping (address => bool) internal blackLists;
    function isBlacklists(address user) public view virtual returns (bool) {
        require(!blackLists[user], "Address is blacklisted");
        return false;
    }

    function addBlackList (address user) public virtual {
        blackLists[user] = true;
        emit AddedBlackList(user);
    }

    function removeBlackList (address user) public virtual{
        blackLists[user] = false;
        emit RemovedBlackList(user);
    }

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    struct XLASwap {
        bytes32 id;
        address swapAccount;
        string xlaAddress;
        uint256 amount;
        uint status;
        bool toXLA;
        string xlaHash;
        uint256 swapTimestamp;
    }

    event XLASwapCreated(XLASwap swap);

    mapping (bytes32 => XLASwap) internal XLASwapData;
    bytes32[] internal XLASwapLists;

    function XLASwapAdd(string calldata xla_address, address user, uint256 amount, bool toXLA, uint status, string calldata xlaHash) external virtual  returns (bytes32){
        require(amount > 0 && amount < (2**256 - 1), "XLASwap: Invalid amount");
        if(toXLA){
            require(balanceOf(user) < amount, "ERC20: burn amount exceeds balance");
        } else {

        }
        

        bytes32 id = keccak256(abi.encodePacked(block.number, block.timestamp, xla_address,user,amount,toXLA));
        require(XLASwapData[id].id != id, "Transaction already generated for swap");
        XLASwap memory swap;
        swap.swapAccount = user;
        swap.amount = amount;
        swap.toXLA = toXLA;
        swap.status = 0;
        swap.xlaHash = xlaHash;
        swap.status = status;
        swap.xlaAddress = xla_address;
        swap.swapTimestamp = block.timestamp;
        swap.id = id;
        XLASwapLists.push(id);
        XLASwapData[id] = swap;
        emit XLASwapCreated(swap);

        return id;
    }

    function XLASwapById(bytes32 id) public view returns(XLASwap memory) {
        require(XLASwapData[id].amount > 0, "XLASwap: Invalid swap");
        return XLASwapData[id];
    }


    function XLASwapTransactions(uint page) public view virtual returns(bytes32[] memory) {
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

}

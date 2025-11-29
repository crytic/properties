// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./tokens/StandardERC20.sol";
import "./tokens/MissingReturns.sol";
import "./tokens/ReturnsFalse.sol";
import "./tokens/TransferFee.sol";
import "./tokens/Reentrant.sol";
import "./tokens/BlockList.sol";
import "./tokens/Pausable.sol";
import "./tokens/RevertZero.sol";
import "./tokens/NoRevert.sol";
import "./tokens/Uint96.sol";
import "./tokens/LowDecimals.sol";
import "./tokens/HighDecimals.sol";
import "./tokens/Bytes32Metadata.sol";
import "./tokens/ApprovalRaceProtection.sol";
import "./tokens/ApprovalToZeroAddress.sol";
import "./tokens/RevertToZero.sol";
import "./tokens/RevertZeroApproval.sol";
import "./tokens/TransferFromSelf.sol";
import "./tokens/TransferMax.sol";
import "./tokens/PermitNoOp.sol";

/**
 * @title ERC20 Edge Cases Helper
 * @author Crytic (Trail of Bits)
 * @notice Deploys and manages all known ERC20 edge case tokens for testing
 * @dev Use this helper to test protocols against non-standard ERC20 behaviors
 *
 * This helper deploys 20 different ERC20 token implementations covering all known
 * edge cases and non-standard behaviors found in real tokens. Import this contract
 * in your test harness to automatically test your protocol against:
 *
 * - Missing return values (USDT, BNB, OMG)
 * - Transfer fees (STA, PAXG)
 * - Reentrant callbacks (AMP, imBTC)
 * - Admin controls (USDC blocklist, BNB pause)
 * - Approval quirks (USDT race protection, UNI uint96)
 * - And many more...
 *
 * @custom:usage
 * ```solidity
 * import "@crytic/properties/contracts/util/erc20/ERC20EdgeCases.sol";
 *
 * contract MyTest {
 *     ERC20EdgeCases edgeCases;
 *
 *     constructor() {
 *         edgeCases = new ERC20EdgeCases();
 *     }
 *
 *     function test_protocolWithAllTokens() public {
 *         address[] memory tokens = edgeCases.all_erc20();
 *         for (uint i = 0; i < tokens.length; i++) {
 *             // Test your protocol with each token
 *         }
 *     }
 * }
 * ```
 *
 * @custom:see https://github.com/d-xo/weird-erc20
 * @custom:see https://github.com/crytic/building-secure-contracts/blob/master/development-guidelines/token_integration.md
 */
contract ERC20EdgeCases {
    // Arrays to store deployed token addresses
    address[] private _standardTokens;
    address[] private _nonStandardTokens;
    address[] private _allTokens;

    // Named access to specific token types
    mapping(string => address) public tokenByName;

    /**
     * @notice Constructor deploys all token types
     * @dev Tokens are deployed with 1M supply to deployer
     */
    constructor() {
        _deployAllTokens();
    }

    /**
     * @notice Get all standard-compliant ERC20 tokens
     * @return Array of token addresses that follow ERC20 standard
     */
    function all_erc20_standard() public view returns (address[] memory) {
        return _standardTokens;
    }

    /**
     * @notice Get all non-standard ERC20 tokens with edge case behaviors
     * @return Array of token addresses with non-standard behaviors
     */
    function all_erc20_non_standard() public view returns (address[] memory) {
        return _nonStandardTokens;
    }

    /**
     * @notice Get all tokens (standard + non-standard)
     * @return Array of all deployed token addresses
     */
    function all_erc20() public view returns (address[] memory) {
        return _allTokens;
    }

    /**
     * @notice Get categorized tokens by behavior type
     * @return Array of token addresses in the specified category
     */
    function tokens_missing_return_values() public view returns (address[] memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = tokenByName["MissingReturns"];
        tokens[1] = tokenByName["ReturnsFalse"];
        return tokens;
    }

    function tokens_with_fee() public view returns (address[] memory) {
        address[] memory tokens = new address[](1);
        tokens[0] = tokenByName["TransferFee"];
        return tokens;
    }

    function tokens_reentrant() public view returns (address[] memory) {
        address[] memory tokens = new address[](1);
        tokens[0] = tokenByName["Reentrant"];
        return tokens;
    }

    function tokens_with_admin_controls() public view returns (address[] memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = tokenByName["BlockList"];
        tokens[1] = tokenByName["Pausable"];
        return tokens;
    }

    function tokens_approval_quirks() public view returns (address[] memory) {
        address[] memory tokens = new address[](4);
        tokens[0] = tokenByName["ApprovalRaceProtection"];
        tokens[1] = tokenByName["ApprovalToZeroAddress"];
        tokens[2] = tokenByName["RevertZeroApproval"];
        tokens[3] = tokenByName["Uint96"];
        return tokens;
    }

    /**
     * @dev Internal function to deploy all token types
     */
    function _deployAllTokens() internal {
        // Deploy standard token
        address standard = address(new StandardERC20());
        _standardTokens.push(standard);
        _allTokens.push(standard);
        tokenByName["Standard"] = standard;

        // Deploy MissingReturns (USDT, BNB, OMG-like)
        address missingReturns = address(new MissingReturns());
        _nonStandardTokens.push(missingReturns);
        _allTokens.push(missingReturns);
        tokenByName["MissingReturns"] = missingReturns;
        tokenByName["USDT-like"] = missingReturns;

        // Deploy ReturnsFalse (Tether Gold-like)
        address returnsFalse = address(new ReturnsFalse());
        _nonStandardTokens.push(returnsFalse);
        _allTokens.push(returnsFalse);
        tokenByName["ReturnsFalse"] = returnsFalse;
        tokenByName["TetherGold-like"] = returnsFalse;

        // Deploy TransferFee (STA, PAXG-like) with 1% fee
        address transferFee = address(new TransferFee(100));
        _nonStandardTokens.push(transferFee);
        _allTokens.push(transferFee);
        tokenByName["TransferFee"] = transferFee;
        tokenByName["STA-like"] = transferFee;
        tokenByName["PAXG-like"] = transferFee;

        // Deploy Reentrant (ERC777, AMP, imBTC-like)
        address reentrant = address(new Reentrant());
        _nonStandardTokens.push(reentrant);
        _allTokens.push(reentrant);
        tokenByName["Reentrant"] = reentrant;
        tokenByName["ERC777-like"] = reentrant;
        tokenByName["AMP-like"] = reentrant;

        // Deploy BlockList (USDC, USDT-like)
        address blockList = address(new BlockList());
        _nonStandardTokens.push(blockList);
        _allTokens.push(blockList);
        tokenByName["BlockList"] = blockList;
        tokenByName["USDC-blocklist"] = blockList;

        // Deploy Pausable (BNB, ZIL-like)
        address pausable = address(new Pausable());
        _nonStandardTokens.push(pausable);
        _allTokens.push(pausable);
        tokenByName["Pausable"] = pausable;
        tokenByName["BNB-like"] = pausable;

        // Deploy RevertZero (LEND-like)
        address revertZero = address(new RevertZero());
        _nonStandardTokens.push(revertZero);
        _allTokens.push(revertZero);
        tokenByName["RevertZero"] = revertZero;
        tokenByName["LEND-like"] = revertZero;

        // Deploy NoRevert (ZRX, EURS-like)
        address noRevert = address(new NoRevert());
        _nonStandardTokens.push(noRevert);
        _allTokens.push(noRevert);
        tokenByName["NoRevert"] = noRevert;
        tokenByName["ZRX-like"] = noRevert;

        // Deploy Uint96 (UNI, COMP-like)
        address uint96 = address(new Uint96());
        _nonStandardTokens.push(uint96);
        _allTokens.push(uint96);
        tokenByName["Uint96"] = uint96;
        tokenByName["UNI-like"] = uint96;
        tokenByName["COMP-like"] = uint96;

        // Deploy LowDecimals (USDC, Gemini-like)
        address lowDecimals = address(new LowDecimals());
        _nonStandardTokens.push(lowDecimals);
        _allTokens.push(lowDecimals);
        tokenByName["LowDecimals"] = lowDecimals;
        tokenByName["USDC-decimals"] = lowDecimals;

        // Deploy HighDecimals (YAM-V2-like)
        address highDecimals = address(new HighDecimals());
        _nonStandardTokens.push(highDecimals);
        _allTokens.push(highDecimals);
        tokenByName["HighDecimals"] = highDecimals;
        tokenByName["YAM-like"] = highDecimals;

        // Deploy Bytes32Metadata (MKR-like)
        address bytes32Metadata = address(new Bytes32Metadata());
        _nonStandardTokens.push(bytes32Metadata);
        _allTokens.push(bytes32Metadata);
        tokenByName["Bytes32Metadata"] = bytes32Metadata;
        tokenByName["MKR-like"] = bytes32Metadata;

        // Deploy ApprovalRaceProtection (USDT, KNC-like)
        address approvalRace = address(new ApprovalRaceProtection());
        _nonStandardTokens.push(approvalRace);
        _allTokens.push(approvalRace);
        tokenByName["ApprovalRaceProtection"] = approvalRace;
        tokenByName["USDT-approval"] = approvalRace;

        // Deploy ApprovalToZeroAddress (OpenZeppelin-like)
        address approvalToZero = address(new ApprovalToZeroAddress());
        _nonStandardTokens.push(approvalToZero);
        _allTokens.push(approvalToZero);
        tokenByName["ApprovalToZeroAddress"] = approvalToZero;
        tokenByName["OpenZeppelin-approval"] = approvalToZero;

        // Deploy RevertToZero (OpenZeppelin-like)
        address revertToZero = address(new RevertToZero());
        _nonStandardTokens.push(revertToZero);
        _allTokens.push(revertToZero);
        tokenByName["RevertToZero"] = revertToZero;
        tokenByName["OpenZeppelin-transfer"] = revertToZero;

        // Deploy RevertZeroApproval (BNB-like)
        address revertZeroApproval = address(new RevertZeroApproval());
        _nonStandardTokens.push(revertZeroApproval);
        _allTokens.push(revertZeroApproval);
        tokenByName["RevertZeroApproval"] = revertZeroApproval;
        tokenByName["BNB-approval"] = revertZeroApproval;

        // Deploy TransferFromSelf (DSToken, WETH-like)
        address transferFromSelf = address(new TransferFromSelf());
        _nonStandardTokens.push(transferFromSelf);
        _allTokens.push(transferFromSelf);
        tokenByName["TransferFromSelf"] = transferFromSelf;
        tokenByName["DSToken-like"] = transferFromSelf;
        tokenByName["WETH-like"] = transferFromSelf;

        // Deploy TransferMax (cUSDCv3-like)
        address transferMax = address(new TransferMax());
        _nonStandardTokens.push(transferMax);
        _allTokens.push(transferMax);
        tokenByName["TransferMax"] = transferMax;
        tokenByName["cUSDCv3-like"] = transferMax;

        // Deploy PermitNoOp (WETH-like)
        address permitNoOp = address(new PermitNoOp());
        _nonStandardTokens.push(permitNoOp);
        _allTokens.push(permitNoOp);
        tokenByName["PermitNoOp"] = permitNoOp;
        tokenByName["WETH-permit"] = permitNoOp;
    }
}

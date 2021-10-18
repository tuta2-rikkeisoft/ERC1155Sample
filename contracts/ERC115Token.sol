// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

import "./IERC1155.sol";
import "./ERC1155TokenReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC1155Token is ERC1155 {
    using Address for address;
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApproval;
    
    // Used as the URI for all token types by relying on ID substitution
    // string private _uri;

    //@dev Sets a new URI for all token types, by relying on the token type ID
    // function _setURI(string memory newuri) internal virtual {
    //     _uri = newuri;
    // }
    
    function create(uint256 _initialSupply, uint256 _id) external returns(uint256) {
        _mint(msg.sender,_id,_initialSupply,"");
        return _id;
    }

    function destroy(uint256 _initialSupply, uint256 _id) external {
        _burn(msg.sender,_id,_initialSupply);
    }
    
    function balanceOf(address _owner, uint256 _id) external view override returns (uint256){
        require(_owner != address(0), "balance query for the zero address");
        return _balances[_id][_owner];
    }
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view override returns (uint256[] memory){
        require(_owners.length == _ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            batchBalances[i] = _balances[_ids[i]][_owners[i]];
        }

        return batchBalances;
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override{
        _setApprovalForAll(msg.sender, _operator, _approved);
    }
    
    /**
     * @dev Approve `_operator` to operate on all of `_owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        require(_owner != _operator, "ERC1155: setting approval status for self");
        _operatorApproval[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool){
        return _operatorApproval[_owner][_operator];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override{
        require(
            _from == msg.sender || _operatorApproval[_from][msg.sender],
            "caller is not owner nor approved"
        );
        _safeTransferFrom(_from, _to, _id, _value, _data);
    }
    
    /**
     * @dev Transfers `_value` tokens of token type `_id` from `_from` to `_to`.
     *
     * Emits a {TransferSingle} event.
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal virtual {
        require(_to != address(0), "transfer to the zero address");

        address operator = msg.sender;

        uint256 fromBalance = _balances[_id][_from];
        require(fromBalance >= _value, "insufficient balance for transfer");
        unchecked {
            _balances[_id][_from] = fromBalance - _value;
        }
        _balances[_id][_to] += _value;

        emit TransferSingle(operator, _from, _to, _id, _value);
        
        _doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _value,_data);
    }
    
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != ERC1155TokenReceiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override{
        require(
            _from == msg.sender || _operatorApproval[_from][msg.sender],
            "transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }
    
    /**
     * @dev Transfers by batch `_values` tokens of token type `_ids` from `_from` to `_to`.
     *
     * Emits a {TransferBatch} event.
     */
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) internal virtual {
        require(_ids.length == _values.length, "ids and amounts length mismatch");
        require(_to != address(0), "transfer to the zero address");

        address operator = msg.sender;
        
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            uint256 fromBalance = _balances[id][_from];
            require(fromBalance >= value, "insufficient balance for transfer");
            unchecked {
                _balances[id][_from] = fromBalance - value;
            }
            _balances[id][_to] += value;
        }

        emit TransferBatch(operator, _from, _to, _ids, _values);
        
        _doSafeBatchTransferAcceptanceCheck(operator, _from, _to, _ids, _values, _data);
    }
    
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != ERC1155TokenReceiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    
    /**
     * @dev Creates `_amount` tokens of token type `_id`, and assigns them to `_to`.
     *
     * Emits a {TransferSingle} event.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual {
        require(_to != address(0), "mint to the zero address");

        address operator = msg.sender;

        _balances[_id][_to] += _amount;
        emit TransferSingle(operator, address(0), _to, _id, _amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), _to, _id, _amount, _data);
    }
    
    /**
     * @dev Creates batch by `_amounts` tokens of token type `_ids`, and assigns them to `_to`.
     *
     * Emits a {TransferSingle} event.
     */
     function _mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual {
        require(_to != address(0), "mint to the zero address");
        require(_ids.length == _amounts.length, "ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < _ids.length; i++) {
            _balances[_ids[i]][_to] += _amounts[i];
        }

        emit TransferBatch(operator, address(0), _to, _ids, _amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), _to, _ids, _amounts, _data);
    }
    
    /**
     * @dev Destroys `_amount` tokens of token type `_id` from `_from`
     * 
     * Emits a {TransferSingle} event.
     */
    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), "burn from the zero address");

        address operator = msg.sender;


        uint256 fromBalance = _balances[_id][_from];
        require(fromBalance >= _amount, "burn amount exceeds balance");
        unchecked {
            _balances[_id][_from] = fromBalance - _amount;
        }

        emit TransferSingle(operator, _from, address(0), _id, _amount);
    }
    
    /**
     * @dev Destroys by batch `_amounts` tokens of token type `_ids` from `_from`
     * 
     * Emits a {TransferSingle} event.
     */
    function _burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal virtual {
        require(_from != address(0), "burn from the zero address");
        require(_ids.length == _amounts.length, "ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            uint256 fromBalance = _balances[id][_from];
            require(fromBalance >= amount, "burn amount exceeds balance");
            unchecked {
                _balances[id][_from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, _from, address(0), _ids, _amounts);
    }
}
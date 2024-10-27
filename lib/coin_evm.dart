library coin_evm;

export 'coin.dart';

// RLP (needed for EVM serialization)
export 'src/encode/rlp.dart';

// EVM primitives
export 'src/ext/evm/evm_addr.dart';
export 'src/ext/evm/evm_chain.dart';
export 'src/ext/evm/evm_chains.dart';
export 'src/ext/evm/evm_tx.dart';
export 'src/ext/evm/evm_tx_signer.dart';
export 'src/ext/evm/access_list.dart';
export 'src/ext/evm/authorization.dart';
export 'src/ext/evm/blob.dart';
export 'src/ext/evm/typed_data.dart';
export 'src/ext/evm/personal_sign.dart';
export 'src/ext/evm/token_amount.dart';

// ABI encoding
export 'src/ext/abi/sol_codec.dart';
export 'src/ext/abi/sol_type.dart';
export 'src/ext/abi/sol_parser.dart';
export 'src/ext/abi/sol_function.dart';
export 'src/ext/abi/sol_types/address_type.dart';
export 'src/ext/abi/sol_types/bool_type.dart';
export 'src/ext/abi/sol_types/bytes_type.dart';
export 'src/ext/abi/sol_types/int_type.dart';
export 'src/ext/abi/sol_types/uint_type.dart';
export 'src/ext/abi/sol_types/string_type.dart';
export 'src/ext/abi/sol_types/array_type.dart';
export 'src/ext/abi/sol_types/tuple_type.dart';

// Smart contracts
export 'src/ext/contract/deployed_contract.dart';
export 'src/ext/contract/call_builder.dart';
export 'src/ext/contract/invoke_builder.dart';
export 'src/ext/contract/token_contracts/fungible_token.dart';
export 'src/ext/contract/token_contracts/collectible_token.dart';
export 'src/ext/contract/token_contracts/multi_token.dart';

// EVM providers
export 'src/ext/provider/evm_provider/json_rpc_link.dart';
export 'src/ext/provider/evm_provider/chain_reader.dart';
export 'src/ext/provider/evm_provider/chain_writer.dart';
export 'src/ext/provider/evm_provider/rpc_middleware.dart';

// Key agents
export 'src/ext/key_agent/key_agent.dart';
export 'src/ext/key_agent/secret_key_agent.dart';
export 'src/ext/key_agent/hardware_agent.dart';

// Account abstraction (ERC-4337)
export 'src/ext/smart_wallet/user_intent.dart';
export 'src/ext/smart_wallet/bundler_link.dart';
export 'src/ext/smart_wallet/delegated_account.dart';
export 'src/ext/smart_wallet/gas_sponsor.dart';

// Name resolution (ENS)
export 'src/ext/naming/name_resolver.dart';
export 'src/ext/naming/name_records.dart';
export 'src/ext/naming/multichain_names.dart';

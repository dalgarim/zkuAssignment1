#!/bin/bash 
if [ $# -ne 2 ]; then
 echo "Usage: $0 param1 param2"
 echo "param1: file name"
 echo "param2: tau ceremony power"
 exit -1
else
 echo "ok" 
fi

filename=$1
power=$2
project=`echo $filename | sed "s/.circom//g"`

# Compile the circuit
circom $filename --r1cs --wasm --sym --c

# Computing the witness with WebAssembly
cp ./input.json "./${project}_js/"
cd "./${project}_js/"
node generate_witness.js "${project}.wasm" input.json witness.wtns
mv ./witness.wtns ../witness.wtns
cd ..

# Start a new "powers of tau" ceremony
snarkjs powersoftau new bn128 $power "pot${power}_0000.ptau" -v

# contribute to the ceremony
snarkjs powersoftau contribute "pot${power}_0000.ptau" "pot${power}_0001.ptau" --name="First contribution" -v

# start the generation of phase2
snarkjs powersoftau prepare phase2 "pot${power}_0001.ptau" "pot${power}_final.ptau" -v

# Generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions
snarkjs groth16 setup "${project}.r1cs" "pot${power}_final.ptau" "${project}_0000.zkey"

# Contribute to the phase 2 of the ceremony
snarkjs zkey contribute "${project}_0000.zkey" "${project}_0001.zkey" --name="1st Contributor Name" -v

# Export the verification key
snarkjs zkey export verificationkey "${project}_0001.zkey" verification_key.json

# Generate a zk-proof associated to the circuit and the witness
snarkjs groth16 prove "${project}_0001.zkey" witness.wtns proof.json public.json

# Verify the proof
snarkjs groth16 verify verification_key.json public.json proof.json

# Generate the Solidity code
snarkjs zkey export solidityverifier "${project}_0001.zkey" verifier.sol

# Generate the parameters of the call
snarkjs generatecall


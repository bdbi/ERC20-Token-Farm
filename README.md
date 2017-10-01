# Token Farm

Just some contracts made for fun.
A simple Token Farm acting as a pos-like contract where "seed" tokens can generate "harvestable" tokens after certain blocks.
Parameters like blocks to wait and tokens generation are customizable by the farm owner and not retroactive

## Usage

TokenFarm is set as "harvester" of the Harvestable Token.
User plants the desired amount of seeds in the Farm contract and stores the deed.
User harvests his tokens presenting the deed received previously after a certain amount of blocks specified into the deed.
Tokens are sent directly to the user, or stored in the farm contract to be withdrawable later on.
A deed is renewable if desired, this option is turned off by default.
If a user plants seeds but does not harvest them for 2 cycles can be subject to expropriation.

## Further improvements

I want to improve the expropriation system making sure to press every seed holder to plant his seeds to avoid inactivity, maybe adding some form of "Account" structure.
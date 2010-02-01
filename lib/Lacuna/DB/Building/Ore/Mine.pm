package Lacuna::DB::Building::Ore::Mine;

use Moose;
extends 'Lacuna::DB::Building::Ore';

has '+image' => ( 
    default => 'mine', 
);

has '+name' => (
    default => 'Mine',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -10,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 85,
);

has '+time_to_build' => (
    default => 100,
);

has '+food_production' => (
    default => -1,
);

has '+energy_production' => (
    default => -10,
);

has '+ore_production' => (
    default => 10,
);

has '+water_production' => (
    default => -10,
);

has '+waste_production' => (
    default => 3,
);



no Moose;
__PACKAGE__->meta->make_immutable;

package Lacuna::DB::Building::Energy::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'energy-reserve', 
);

has '+name' => (
    default => 'Energy Reserve',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -100,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 200,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_production' => (
    default => -2,
);

has '+energy_production' => (
    default => -10,
);

has '+ore_production' => (
    default => -3,
);

has '+water_production' => (
    default => -1,
);

has '+waste_production' => (
    default => 1,
);

has '+energy_storage' => (
    default => 1500,
);



no Moose;
__PACKAGE__->meta->make_immutable;

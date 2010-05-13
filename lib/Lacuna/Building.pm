package Lacuna::Building;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub model_domain {
    return $_[0]->model_class->domain_name;
}

sub model_class {
    confess "you need to override me";
}

sub app_url {
    confess "you need to override me";
}

sub to_app_with_url {
    my $self = shift;
    return ($self->app_url => $self->to_app);
}

sub upgrade {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);

    # check the upgrade lock
    if ($building->is_upgrade_locked) {
        confess [1013, "An upgrade request is already being processed on this building."];
    }
    else {
        $building->lock_upgrade;
    }

    # verify upgrade
    my $cost = $building->cost_to_upgrade;
    $building->can_upgrade($cost);

    # spend resources
    my $body = $building->body;
    if ($building->has_free_upgrade) {
        $body->spend_freebie($building->class)->put;
    }
    else {
        $body->spend_water($cost->{water});
        $body->spend_energy($cost->{energy});
        $body->spend_food($cost->{food});
        $body->spend_ore($cost->{ore});
        $body->add_waste($cost->{waste});
        $body->update;
    }

    $building->start_upgrade($cost);

    $empire->trigger_full_update;
    
    return {
        status      => $empire->get_status,
        building    => {
            id              => $building->id,
            level           => $building->level,
            pending_build   => $building->upgrade_status,
        },
    };
}

sub view {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    my $cost = $building->cost_to_upgrade;
    my $can_upgrade = eval{$building->can_upgrade($cost)};
    my $reason = $@;
    my $image_after_upgrade = $building->image_level($building->level + 1);

    my %out = ( 
        building    => {
            id                  => $building->id,
            name                => $building->name,
            image               => $building->image_level,
            x                   => $building->x,
            y                   => $building->y,
            level               => $building->level,
            food_hour           => $building->food_hour,
            food_capacity       => $building->food_capacity,
            ore_hour            => $building->ore_hour,
            ore_capacity        => $building->ore_capacity,
            water_hour          => $building->water_hour,
            water_capacity      => $building->water_capacity,
            waste_hour          => $building->waste_hour,
            waste_capacity      => $building->waste_capacity,
            energy_hour         => $building->energy_hour,
            energy_capacity     => $building->energy_capacity,
            happiness_hour      => $building->happiness_hour,
            upgrade             => {
                can             => ($can_upgrade ? 1 : 0),
                reason          => $reason,
                cost            => $cost,
                production      => $building->stats_after_upgrade,
                image           => $image_after_upgrade,
            },
        },
        status      => $empire->get_status,
    );
    if (defined $building->is_upgrading) {
        $out{building}{pending_build} = $building->upgrade_status;
    }
    return \%out;
}

sub build {
    my ($self, $session_id, $body_id, $x, $y) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);

    # check the plot lock
    if ($body->is_plot_locked($x, $y)) {
        confess [1013, "That plot is reserved for another building.", [$x,$y]];
    }
    else {
        $body->lock_plot($x,$y);
    }
    
    # prepare the body for the building
    $body->tick;

    # create dummy building
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => $x,
        y               => $y,
        level           => 0,
        body_id         => $body->id,
        body            => $body,
        class           => $self->model_class,
    });

    # make sure the planet can handle it
    $body = $body->can_build_building($building);

    # adjust resources
    if ($building->has_free_build) {
        $body->spend_freebie($building->class)->put;
    }
    else {
        $body->spend_food($building->food_to_build);
        $body->spend_water($building->water_to_build);
        $body->add_waste($building->waste_to_build);
        $body->spend_ore($building->ore_to_build);
        $body->spend_energy($building->energy_to_build);
        $body->update;
    }

    # build it
    $body->build_building($building);
    
    # show the user
    return {
        status      => $empire->get_status,
        building    => {
            id              => $building->id,
            level           => $building->level,
            pending_build   => $building->upgrade_status,
        },
    };
}

sub get_stats_for_level {
    my ($self, $session_id, $building_id, $level) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    if ($level < 0 || $level > 100) {
        confess [1009, 'Level must be an integer between 1 and 100.'];
    }
    $building->level($level);
    my $image_after_upgrade = $building->image_level($building->level + 1);
    return {
        building    => {
            id                  => $building->id,
            name                => $building->name,
            image               => $building->image_level,
            level               => $building->level,
            food_hour           => $building->food_hour,
            food_capacity       => $building->food_capacity,
            ore_hour            => $building->ore_hour,
            ore_capacity        => $building->ore_capacity,
            water_hour          => $building->water_hour,
            water_capacity      => $building->water_capacity,
            waste_hour          => $building->waste_hour,
            waste_capacity      => $building->waste_capacity,
            energy_hour         => $building->energy_hour,
            energy_capacity     => $building->energy_capacity,
            happiness_hour      => $building->happiness_hour,
            upgrade             => {
                cost            => $building->cost_to_upgrade,
                production      => $building->stats_after_upgrade,
                image           => $image_after_upgrade,
            },
        },
        status      => $empire->get_status,
    };
}


__PACKAGE__->register_rpc_method_names(qw(upgrade view build get_stats_for_level));

no Moose;
__PACKAGE__->meta->make_immutable;


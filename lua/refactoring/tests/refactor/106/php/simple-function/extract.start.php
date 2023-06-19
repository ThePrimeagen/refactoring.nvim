<?php

namespace Module;

function simple_function($a)
{
    $test = 1;
    $test_other = 11;
    for ($idx = $test - 1; $idx < $test_other; ++$idx) {
        print $idx;
        print $a;
    }
}

<?php

class RefuctorPlease
{
    public function foo_bar (
        $a, $test
    ) {
        $test_other = 11;
        for ($idx = $test - 1; $idx < $test_other; ++$idx) {
            print $idx;
            print $a;
        }
        return $test_other;
    }

    public function multiple_returns($a)
    {
        $test = 1;
        $test_other = $this->foo_bar($a, $test);


        return $test_other;
    }
}

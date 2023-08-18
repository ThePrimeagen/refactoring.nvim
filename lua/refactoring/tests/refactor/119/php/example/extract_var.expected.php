<?php

class Order 
{
    public $quantity;
    public $itemPrice;
}

class testing 
{
    public function orderCalculation(
        Order $order, int $blah, int $nonsence
    ) 
    {
        $blah * $nonsence;
        $basePrice = $order->quantity 
            *
            $order->itemPrice;
        $basePrice;

        return $basePrice - 
            max(0, $order->quantity - 500) * $order->itemPrice * 0.5 +
            min($basePrice * 0.1, 100);
    }
}

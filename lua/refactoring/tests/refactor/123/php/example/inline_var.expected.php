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
        
        $order->quantity*$order->itemPrice;

        return $order->quantity*$order->itemPrice - 
            max(0, $order->quantity - 500) * $order->itemPrice * 0.5 +
            min($order->quantity*$order->itemPrice * 0.1, 100);
    }
}

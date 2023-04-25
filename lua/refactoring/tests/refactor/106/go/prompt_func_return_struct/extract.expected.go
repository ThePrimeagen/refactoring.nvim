package main

type Slicer struct {
    s []int
}

func (s Slicer) sumSlice() int {
    sum := 0
    for _, val := range s.s {
        sum += val
    }
    return sum
}

func (s Slicer) Sum() int {
    sum := s.sumSlice()


    return sum
}

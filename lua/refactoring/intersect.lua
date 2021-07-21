
-- Array<node_wrapper>
local intersect_nodes = function(nodes, row, col)
    local found = {}
    for idx = 1, #nodes do
        local node = nodes[idx]
        local sRow = node.dim.s.r
        local sCol = node.dim.s.c
        local eRow = node.dim.e.r
        local eCol = node.dim.e.c
        if utils.intersects(row, col, sRow, sCol, eRow, eCol) then
            table.insert(found, node)
        end
    end
    return found
end


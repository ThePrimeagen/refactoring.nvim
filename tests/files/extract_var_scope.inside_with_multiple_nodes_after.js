Object.entries(processedLinesBySubroute).forEach(([key, processedLine]) => {
  allLinesWithKey.forEach(([line, lineKey]) => {
    const foo = processedLine.lines.some((l) => l.id === line.id);
    if (
      foo ||
      !lineKey.includes(key)
    )
      return;
    processedLine.lines.push(line);
  });
});

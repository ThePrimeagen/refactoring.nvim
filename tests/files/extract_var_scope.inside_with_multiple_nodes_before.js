Object.entries(processedLinesBySubroute).forEach(([key, processedLine]) => {
  allLinesWithKey.forEach(([line, lineKey]) => {
    if (
      processedLine.lines.some((l) => l.id === line.id) ||
      !lineKey.includes(key)
    )
      return;
    processedLine.lines.push(line);
  });
});

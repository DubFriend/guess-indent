{CompositeDisposable} = require 'atom'

getIndentationStats = (lines) ->
  tabIndentCount = 0
  spaceIndentCount = 0

  lastStats = {
    tabCount: 0,
    spaceCount: 0
  }

  spaceCounts = {}

  lines.forEach (line) =>
    whitespace = line.match(/^\s*/)[0]
    stats = {
      tabCount: whitespace.replace(/\ /g, '').length,
      spaceCount: whitespace.replace(/\t/g, '').length
    }

    if stats.tabCount == 0 and lastStats.tabCount == 0
      spaceIndentCount += 1
      delta = Math.abs(stats.spaceCount - lastStats.spaceCount)
      if delta
        if not spaceCounts[delta]
          spaceCounts[delta] = 1
        else
          spaceCounts[delta] += 1

    if stats.spaceCount == 0 and lastStats.spaceCount == 0
      tabIndentCount += 1

    lastStats = stats

  mostCommonTabLength = 0
  greatestFrequency = 0
  for tabLength, frequency of spaceCounts
    if frequency > greatestFrequency
      mostCommonTabLength = tabLength
      greatestFrequency = frequency

  return {
    tabIndentCount: tabIndentCount,
    spaceIndentCount: spaceIndentCount,
    mostCommonTabLength: Number(mostCommonTabLength),
    frequency: greatestFrequency
  }

module.exports =
  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.observeActivePaneItem (item) =>
      editor = atom.workspace.getActiveTextEditor()
      if editor
        defaultIsSoftTabs = atom.config.get("editor.softTabs", scope: editor.getRootScopeDescriptor().scopes)
        defaultTabLength = atom.config.get("editor.tabLength", scope: editor.getRootScopeDescriptor().scopes)
        stats = getIndentationStats editor.buffer.getLines()
        if stats.tabIndentCount >= stats.spaceIndentCount and stats.tabIndentCount >= 2
          editor.setSoftTabs false
          editor.setTabLength defaultTabLength
        else if stats.tabIndentCount < stats.spaceIndentCount and stats.frequency >= 2
          editor.setSoftTabs true
          editor.setTabLength(stats.mostCommonTabLength or defaultTabLength)
        else
          editor.setSoftTabs defaultIsSoftTabs
          editor.setTabLength defaultTabLength

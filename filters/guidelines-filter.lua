function Div(div)
  if div.classes:includes('guidelines') then
    -- Create the link node
    local link = pandoc.Link(
      {pandoc.Str("🔗")},    -- Link text (icon)
      "#sec-guidelines"      -- Link target (as HTML anchor)
    )
    -- Create the title: link + space + bold text + colon
    local title = pandoc.Para{
      link,
      pandoc.Space(),
      pandoc.Strong{pandoc.Str("Reproducibility guidelines:")}
    }
    -- Insert the title at the top of the callout
    table.insert(div.content, 1, title)
    return div
  end
end

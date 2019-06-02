library(tidyverse)

extract_133 <- function(x) {
  x %>%
    read_lines() %>%
    .[. != ""] %>%
    enframe("line", "text") %>%
    mutate(
      part = case_when(
        str_detect(text, "^\t[^\t][[:upper:]]") ~ str_squish(str_remove_all(text, "\t")),
        TRUE ~ NA_character_
      ),
      setting = case_when(
        str_detect(text, "^\t[^\t]") ~ str_remove_all(text, "\t"),
        TRUE ~ NA_character_
      ),
      setting = case_when(
        part == setting ~ NA_character_,
        TRUE ~ setting
      ),
      character_line = case_when(
        str_detect(text, "^\t\t\t[^\t]") ~ str_remove_all(text, "\t"),
        TRUE ~ NA_character_
      ),
      character_desc = case_when(
        str_detect(text, "^\t\t\t\t[^\t]") ~ str_remove_all(text, "\t"),
        TRUE ~ NA_character_
      ),
      character = case_when(
        str_detect(text, "^\t\t\t\t\t[^\t]") ~ str_remove_all(text, "\t"),
        TRUE ~ NA_character_
      )
    ) %>%
    fill(part, character, .direction = "down") %>%
    select(-text) %>%
    drop_na(part) %>%
    group_by(id = cumsum(is.na(setting))) %>%
    mutate(
      setting = paste0(setting, collapse = " "),
      setting = str_remove(setting, "NA "),
      setting = ifelse(setting == "NA", NA, setting)
    ) %>%
    ungroup() %>%
    group_by(id = cumsum(is.na(character_line))) %>%
    mutate(
      character_line = paste0(character_line, collapse = " "),
      character_line = str_remove(character_line, "NA ")
    ) %>%
    # fill(character_desc, .direction = "down") %>%
    # filter(!str_detect(character_desc, "^\\(")) %>%
    ungroup() %>%
    fill(setting, .direction = "down") %>%
    group_by(id = cumsum(is.na(character_desc))) %>%
    mutate(
      character_desc = paste0(character_desc, collapse = " "),
      character_desc = str_remove(character_desc, "NA "),
      character_desc = ifelse(character_desc == "NA", NA, character_desc)
    ) %>%
    ungroup() %>%
    filter(character_line != "NA") %>%
    group_by(character_line) %>%
    fill(character_desc, .direction = "down") %>%
    arrange(line) %>%
    ungroup() %>%
    select(-id) %>%
    distinct(part, setting, character_line, character_desc, character, .keep_all = TRUE) %>%
    set_names("id", "perspective", "setting", "line", "description", "character") %>%
    distinct(line, .keep_all = TRUE) %>% # because character line is duplicated at times and the first one is what we want
    select(id, perspective, setting, character, description, line)
}

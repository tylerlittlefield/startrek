## code to prepare `tng` dataset goes here
library(tidyverse)

scripts <- list.files("inst/extdata/scripts-tng", full.names = TRUE)

extract_titles <- function(scripts) {
  message(glue::glue("Fetching titles from: {scripts}"))
  scripts <- list.files(scripts, full.names = TRUE)
  raw <- sapply(scripts, read_lines)
  raw_squished <- lapply(raw, str_squish)
  raw_rm_empty <- lapply(raw_squished, function(x) x[x != ""])
  output <- gsub('"', "", unlist(unname(lapply(raw_rm_empty, `[[`, 2))))
  rm("raw", "raw_squished", "raw_rm_empty")
  output
}

scripts_to_df <- function(x) {
  message("Converting scripts to dataframes")
  read_lines(x, progress = TRUE) %>%
    .[. != ""] %>%
    enframe("line", "text") %>%
    mutate(
      part = case_when(
        str_detect(text, "^[0-9]") ~ str_squish(str_remove_all(text, "\t")),
        TRUE ~ NA_character_
      ),
      setting = case_when(
        str_detect(text, "^\t[^\t]") ~ str_remove_all(text, "\t"),
        TRUE ~ NA_character_
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
    # group_by(character) %>%
    # fill(character_desc, .direction = "down") %>%
    # ungroup() %>%
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
    fill(character_desc) %>%
    ungroup() %>%
    select(-id) %>%
    distinct(part, setting, character_line, character_desc, character) %>%
    set_names("perspective", "setting", "line", "description", "character") %>%
    distinct(line, .keep_all = TRUE) %>% # because character line is duplicated at times and the first one is what we want
    select(perspective, setting, character, description, line)
}

titles <- extract_titles("inst/extdata/scripts-tng")
tng <- lapply(scripts, scripts_to_df)

names(tng) <- titles

usethis::use_data(tng)

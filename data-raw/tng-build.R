library(tidyverse)
library(janitor)
library(glue)

source("data-raw/tng-episode-133.R")

extract_titles <- function(scripts) {
  raw <- sapply(scripts, read_lines)
  raw_squished <- lapply(raw, str_squish)
  raw_rm_empty <- lapply(raw_squished, function(x) x[x != ""])
  output <- gsub('"', "", unlist(unname(lapply(raw_rm_empty, `[[`, 2))))
  rm("raw", "raw_squished", "raw_rm_empty")
  output
}

tng_scripts <- list.files("inst/extdata/scripts-tng", full.names = TRUE)

tidy_tng <- function(x) {
  message(glue("Converting [{basename(x)}] from [{gsub(basename(path = x), '', x)}]"))
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
    distinct(line, .keep_all = TRUE) %>%
    select(id, perspective, setting, character, description, line)
}

tng_first <- lapply(tng_scripts[1:31], tidy_tng)
tng_133 <- extract_133(tng_scripts[32])
tng_last <- lapply(tng_scripts[33:176], tidy_tng)

tng_titles <- extract_titles(tng_scripts)
tng <- c(tng_first, list(tng_133), tng_last)
names(tng) <- str_squish(tng_titles)

usethis::use_data(tng, overwrite = TRUE)

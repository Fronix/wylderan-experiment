import { QuartzConfig } from "./quartz/cfg"
import * as Plugin from "./quartz/plugins"

const baseUrl = process.env.BASE_URL ?? "localhost"

/**
 * Quartz 4 Configuration
 *
 * See https://quartz.jzhao.xyz/configuration for more information.
 */
const config: QuartzConfig = {
  configuration: {
    pageTitle: process.env.PAGE_TITLE ?? "Grove",
    pageTitleSuffix: "",
    enableSPA: true,
    enablePopovers: true,
    analytics: null,
    locale: "en-US",
    baseUrl,
    ignorePatterns: ["private", "templates", ".obsidian"],
    defaultDateType: "modified",
    theme: {
      fontOrigin: "googleFonts",
      cdnCaching: true,
      typography: {
        header: "Schibsted Grotesk",
        body: "Source Sans Pro",
        code: "IBM Plex Mono",
      },
      colors: {
        lightMode: {
          light: "#f5f2ed",
          lightgray: "#ddd8d0",
          gray: "#a8a099",
          darkgray: "#3d3730",
          dark: "#1a1613",
          secondary: "#8b4513",
          tertiary: "#6b7c5e",
          highlight: "rgba(139, 69, 19, 0.1)",
          textHighlight: "#f0c67088",
        },
        darkMode: {
          light: "#0f0e0d",
          lightgray: "#2a2725",
          gray: "#5c5550",
          darkgray: "#ccc4bb",
          dark: "#e8e0d6",
          secondary: "#c4864a",
          tertiary: "#7a9468",
          highlight: "rgba(196, 134, 74, 0.12)",
          textHighlight: "#c4864a44",
        },
      },
    },
  },
  plugins: {
    transformers: [
      Plugin.FrontMatter(),
      Plugin.CreatedModifiedDate({
        priority: ["frontmatter", "filesystem"],
      }),
      Plugin.SyntaxHighlighting({
        theme: {
          light: "github-light",
          dark: "github-dark",
        },
        keepBackground: false,
      }),
      Plugin.ObsidianFlavoredMarkdown({ enableInHtmlEmbed: false }),
      Plugin.GitHubFlavoredMarkdown(),
      Plugin.TableOfContents(),
      Plugin.CrawlLinks({ markdownLinkResolution: "shortest" }),
      Plugin.Description(),
      Plugin.Latex({ renderEngine: "katex" }),
    ],
    filters: [Plugin.RemoveDrafts()],
    emitters: [
      Plugin.AliasRedirects(),
      Plugin.ComponentResources(),
      Plugin.ContentPage(),
      Plugin.FolderPage(),
      Plugin.TagPage(),
      Plugin.ContentIndex({
        enableSiteMap: true,
        enableRSS: true,
      }),
      Plugin.Assets(),
      Plugin.Static(),
      Plugin.Favicon(),
      Plugin.NotFoundPage(),
    ],
  },
}

export default config

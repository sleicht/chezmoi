// ~/.finicky.js
// Use https://finicky-kickstart.now.sh to generate basic configuration
// Learn more about configuration options: https://github.com/johnste/finicky/wiki/Configuration-(v4)
// @ts-check

/**
 * @typedef {import('/Applications/Finicky.app/Contents/Resources/finicky.d.ts').FinickyConfig} FinickyConfig
 */

/**
 * @type {FinickyConfig}
 */
export default {
  defaultBrowser: "Zen",
  options: {
    // Check for updates. Default: true
    checkForUpdates: true,
    // Log every request to file. Default: false
    logRequests: false,
  },
  rewrite: [
    {
      // Redirect all urls to use https
      match: (url) => url.protocol === "http" && !url.host.endsWith("127.0.0.1"),
      url: (url) => {
        url.protocol = "https";
        return url;
      },
    }
  ],

  handlers: [
    {
      match: "medium.com/*",
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("jetbrains.com"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("google.com"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("skills.google"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("gitlab.com"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("firebaseapp.com"),
      browser: "Google Chrome"
    },
    {
      match: "github.com/*",
      browser: "Google Chrome"
    },
    {
      match: "claude.ai/*",
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("jessie.ai"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("linkedin.com"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("eadminportal.ch"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("email.stripe.com"),
      browser: "Google Chrome"
    },
    {
      match: (url) => url.host.endsWith("connect.nest-info.ch"),
      browser: "Google Chrome"
    },
    {
      match: "apple.com/*",
      browser: "Safari"
    },
    {
      match: (url) => url.host.endsWith("127.0.0.1"),
      browser: "Google Chrome"
    }
  ]
  /*
    handlers: [
      {
        // Open google.com and *.google.com urls in Google Chrome
        match: [
          "google.com*", // match google.com urls
          finicky.matchDomains(/.*\.google.com/) // use helper function to match on domain only
        ],
        browser: "Google Chrome"
      }
    ]
  */
}

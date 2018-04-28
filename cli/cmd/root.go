package cmd

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "cli",
	Short: "cli is a sample command line.",
	Long: `cli is an awesome sample command line
		made by someone with to much free time.`,
	Run: func(cmd *cobra.Command, args []string) {
		cmd.HelpFunc()(cmd, args)
	},
}

// Execute main command, return error if anything goes wrong.
func Execute() error {
	return rootCmd.Execute()
}

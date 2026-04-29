package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/syncloud/golib/log"
	"hooks/installer"
)

func main() {
	logger := log.Logger()

	var rootCmd = &cobra.Command{
		Use:          "post-refresh",
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return installer.New(logger).PostRefresh()
		},
	}

	if err := rootCmd.Execute(); err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}

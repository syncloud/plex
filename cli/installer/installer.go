package installer

import (
	"fmt"
	"os"
	"path"

	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
)

const (
	App      = "plex"
	UserName = "plex"
)

type Variables struct {
	App       string
	AppDir    string
	CommonDir string
	SnapData  string
}

type Installer struct {
	appDir         string
	commonDir      string
	dataDir        string
	configDir      string
	installFile    string
	platformClient *platform.Client
	logger         *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	appDir := fmt.Sprintf("/snap/%s/current", App)
	commonDir := fmt.Sprintf("/var/snap/%s/common", App)
	dataDir := fmt.Sprintf("/var/snap/%s/current", App)
	configDir := path.Join(dataDir, "config")
	return &Installer{
		appDir:         appDir,
		commonDir:      commonDir,
		dataDir:        dataDir,
		configDir:      configDir,
		installFile:    path.Join(commonDir, "installed"),
		platformClient: platform.New(),
		logger:         logger,
	}
}

func (i *Installer) UpdateConfigs() error {
	if err := linux.CreateUser(UserName); err != nil {
		return err
	}

	if err := os.MkdirAll(path.Join(i.commonDir, "log"), 0755); err != nil {
		return err
	}
	if err := os.MkdirAll(path.Join(i.commonDir, "nginx"), 0755); err != nil {
		return err
	}
	if err := os.MkdirAll(path.Join(i.dataDir, "Application_Support"), 0755); err != nil {
		return err
	}

	if _, err := i.platformClient.InitStorage(App, UserName); err != nil {
		return err
	}

	variables := Variables{
		App:       App,
		AppDir:    i.appDir,
		CommonDir: i.commonDir,
		SnapData:  i.dataDir,
	}
	if err := config.Generate(
		path.Join(i.appDir, "config"),
		i.configDir,
		variables,
	); err != nil {
		return err
	}

	if err := linux.Chown(i.dataDir, UserName); err != nil {
		return err
	}
	return linux.Chown(i.commonDir, UserName)
}

func (i *Installer) Install() error {
	return i.UpdateConfigs()
}

func (i *Installer) Configure() error {
	if err := i.StorageChange(); err != nil {
		return err
	}
	if _, err := os.Stat(i.installFile); os.IsNotExist(err) {
		if err := os.WriteFile(i.installFile, []byte("installed\n"), 0644); err != nil {
			return err
		}
	}
	return nil
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	return i.UpdateConfigs()
}

func (i *Installer) StorageChange() error {
	_, err := i.platformClient.InitStorage(App, UserName)
	return err
}

func (i *Installer) AccessChange() error {
	return i.UpdateConfigs()
}

func (i *Installer) BackupPreStop() error {
	return nil
}

func (i *Installer) RestorePreStart() error {
	return nil
}

func (i *Installer) RestorePostStart() error {
	return nil
}

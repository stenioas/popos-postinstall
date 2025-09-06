# Pop!\_OS 22.04: guia de instalação com btrfs, criptografia luks e snapshots automáticos com timeshift

Este guia foi desenvolvido com base no trabalho original de **Willi Mutschler**. O texto é uma modificação do <a href="https://mutschler.dev/linux/pop-os-btrfs-22-04/#step-4-reboot-some-checks-and-system-updates" target="_blank">guia original</a>.

Neste guia, mostrarei como instalar o Pop!\_OS 22.04 com a seguinte estrutura:

- uma partição EFI não criptografada para o bootloader systemd.
- uma partição não criptografada para o sistema de recuperação Pop!\_OS.
- uma partição swap criptografada que funciona com hibernação.
- uma partição [btrfs](https://mutschler.dev/linux/btrfs/) criptografada (com LVM) para o sistema de arquivos raiz:
  - O volume lógico btrfs contém um subvolume `@` para /e um subvolume `@home` para /home. Observe que o instalador do Pop!\_OS não cria subvolumes btrfs por padrão, então precisamos fazer isso manualmente.
- Instantâneos automáticos do sistema e reversão fácil usando:
  - [`timeshift`](https://github.com/teejee2008/timeshift) que regularmente tirará instantâneos (quase instantâneos) do sistema.
  - [`timeshift-autosnap-apt`](https://github.com/wmutschl/timeshift-autosnap-apt) que cria um snapshot do btrfs com timeshift em qualquer atualização do sistema com apt.

## Observações gerais

Este guia foi criado com o Pop!\_OS 22.04 da [System76](https://system76.com/pop) copiado para uma mídia de instalação (geralmente um dispositivo USB Flash).

Recomendo fortemente que você tente os seguintes passos de instalação em uma máquina virtual antes de fazer qualquer coisa em um hardware real!

## 1° passo: Prepare as partições executando primeiro uma instalação limpa

Vamos executar primeiro a instalação automática com criptografia. Selecione a região, o idioma e o layout do teclado. Em seguida, escolha `Clean Install`, habilite a criptografia e siga os passos para criar uma conta de usuário e gravar as alterações no disco. Quando terminar, **NÃO** reinicie ou desligue o dispositivo, clique com o botão direito do mouse no aplicativo `Install Pop!_OS` na dock e selecione **Quit**.

## 2° passo: Instale o Pop!\_OS usando a opção Custom(Advanced)

Agora, vamos abrir o instalador novamente na dock, selecionar a região, o idioma e o layout do teclado. Em seguida, escolha `Custom (Advanced)`. Você verá seu disco rígido particionado:

- Clique na primeira partição, marque `Use partition`, marque `Format`, usar como `Boot /boot/efi`, Sistema de arquivos: fat32.
- Clique na segunda partição, marque `Use partition`, use como Custom e digite `/recovery`, Sistema de arquivos: fat32, marque `Format`.
- Clique na terceira e maior partição. Um diálogo `Decrypt This Partition` se abrirá. Digite sua senha do Luks e clique em Decrypt. Um novo dispositivo `LVM data` será exibido (geralmente na parte inferior da tela). Clique nesta partição, marque `Use partition`, marque `Format`, usar como `Root (/)`, Sistema de arquivos: btrfs.
- Clique na quarta partição, marque `Use partition`, usar como `Swap`.

Se você tiver outras partições, verifique seus tipos e uso; em especial, desative o uso de quaisquer outras partições EFI.

Verifique tudo novamente (as partições devem estar com uma marca de seleção preta) e clique em `Erase and Install`. Siga os passos para criar uma conta de usuário e gravar as alterações no disco. Assim que o instalador terminar, **NÃO** selecione "Restart Device" nem "Shut Down", mas mantenha a janela do instalador aberta.

## 3° passo: Pós-instalação

Abra um terminal e mude para uma sessão root interativa:

```bash
sudo -i
```

> 💡 _Você pode achar útil maximizar a janela do terminal para trabalhar com a linha de comando._

Assumindo que você utilizou a partição **/dev/sda3** como `Root (/)` (substitua _sda3_ pela partição que você utilizou, por exemplo, `nvme0n1p3`), vamos montar nossa partição raiz (o volume raiz do btrfs tem sempre o ID 5), mas com algumas opções de montagem que otimizam o desempenho e a durabilidade em unidades SSD ou NVME.

Desbloqueie a partição:

```bash
cryptsetup luksOpen /dev/sda3 cryptdata
```

Digite a senha para a partição.

Às vezes, o grupo LVM não é ativado. O comando abaixo ativa todos os grupos.

```bash
vgchange -a y
```

Monte a partição.

```bash
mount -o subvolid=5,defaults,compress=zstd:1,discard=async /dev/mapper/data-root /mnt
```

Por padrão, o POP!\_OS 22.04 usa as opções de montagem padrão do btrfs, ou seja, os SSDs serão detectados automaticamente (opção de montagem de ssd) e space_cache=v2, que também é o [padrão no Fedora](https://pagure.io/fedora-btrfs/project/issue/24). Há um debate sobre se é melhor usar [noatime em vez do padrão relatime](https://pagure.io/fedora-btrfs/project/issue/9), mas, pessoalmente, não vi nenhuma diferença, então não usarei noatime neste guia. No entanto, descobri que há algumas dicas gerais adicionais a serem usadas:

- `compress=zstd:1`: permite especificar o algoritmo de compressão que queremos usar. O btrfs fornece algoritmos de compressão lzo, zstd e zlib; no entanto, o zstd se tornou o candidato com melhor desempenho. Eu uso o nível 1, pois é recomendado pela [equipe do Fedora em uma máquina de trabalho](https://fedoraproject.org/wiki/Changes/BtrfsTransparentCompression#Simple_Analysis_of_btrfs_zstd_compression_level).
- `discard=async`: isso se tornará o padrão em breve, veja, por exemplo, [habilitar discard=async por padrão](https://pagure.io/fedora-btrfs/project/issue/6).

Mais tarde, também anexaremos essas opções de montagem ao `fstab`, mas é uma boa prática já fazer uso da compactação ao mover os arquivos do sistema da raiz do btrfs para os subvolumes dedicados `@` e `@home`.

### Crie subvolumes btrfs @ e @home

Agora, criaremos o subvolume `@` e moveremos todos os arquivos e pastas do sistema de arquivos da raiz para `@`. Observe que, como usamos as opções de montagem otimizadas, como compactação, estas já serão aplicadas durante o processo de movimentação:

Crie o volume:

```bash
btrfs subvolume create /mnt/@ && cd /mnt && ls | grep -v @ | xargs mv -t @ && ls -a /mnt
```

Verifique:

```bash
ls -a /mnt
```

<pre style="padding-top: 0;">
<code style="color: gray;">
. .. @
</code>
</pre>

Agora vamos criar outro subvolume chamado `@home` e mover a pasta do usuário `/mnt/@/home/` para `@home`:

```bash
btrfs subvolume create /mnt/@home && mv /mnt/@/home/\* /mnt/@home/
```

Verifique:

```bash
ls -a /mnt/@/home
```

<pre style="padding-top: 0;">
<code style="color: gray;">
. ..
</code>
</pre>

```bash
ls -a /mnt/@home
```

<pre style="padding-top: 0;">
<code style="color: gray;">
. .. username
</code>
</pre>

```bash
btrfs subvolume list /mnt
```

<pre style="padding-top: 0;">
<code style="color: gray;">
ID 264 gen 339 top level 5 path @
ID 265 gen 340 top level 5 path @home
</code>
</pre>

### Mudanças no fstab

Precisamos adaptar o fstab para:

- montar o `/` no subvolume `@`.
- montar o `/home` no subvolume `@home`.
- fazer uso de opções de montagem btrfs otimizadas.

Execute:

```bash
sed -i 's/btrfs defaults/btrfs defaults,subvol=@,compress=zstd:1,discard=async/' /mnt/@/etc/fstab && echo "UUID=$(blkid -s UUID -o value /dev/mapper/data-root) /home btrfs defaults,subvol=@home,compress=zstd:1,discard=async 0 0" >> /mnt/@/etc/fstab && cat /mnt/@/etc/fstab
```

Deve ficar parecido com isso:

<pre style="padding-top: 0;">
<code style="color: gray;">
PARTUUID=2ea6ae0f-6b6a-4e4c-8eaa-7fec8dde5162 /boot/efi vfat umask=0077 0 0
PARTUUID=8ce17e3b-3853-4d10-b878-5dd1ccd6fe8a /recovery vfat umask=0077 0 0
/dev/mapper/cryptswap none swap defaults 0 0
UUID=052ec665-cf5d-4372-bb65-1b82237b9101 / btrfs defaults,subvol=@,compress=zstd:1,discard=async 0 0
UUID=052ec665-cf5d-4372-bb65-1b82237b9101 /home btrfs defaults,subvol=@home,compress=zstd:1,discard=async 0 0
</code>
</pre>

Observe que seus números PARTUUID e UUID serão diferentes. As duas últimas linhas de / e /home são as mais importantes.

### Mudanças no crypttab

À medida que usamos `discard=async`, precisamos adicionar `discard` ao `crypttab`:

```bash
sed -i 's/luks/luks,discard/' /mnt/@/etc/crypttab
cat /mnt/@/etc/crypttab
```

<pre style="padding-top: 0;">
<code style="color: gray;">
cryptdata UUID=52d31097-e125-46f0-a139-85087e1b5565 none luks,discard
cryptswap UUID=8cd56bf1-1a43-49c3-98b0-835b658b54fc /dev/urandom swap,plain,offset=1024,cipher=aes-xts-plain64,size=512
</code>
</pre>

Aqui também podemos ver que a partição swap está criptografada e montada em um dispositivo chamado `cryptswap`.

### Ajustar a configuração do kernelstub

Precisamos ajustar algumas configurações do gerenciador de boot systemd e também garantir que essas configurações não sejam sobrescritas se instalarmos ou atualizarmos kernels e módulos. Precisamos adicionar `rootflags=subvol=@` à seção `"user"` do arquivo de configuração do kernelstub:

```bash
nano /mnt/@/etc/kernelstub/configuration
```

Aqui você precisa adicionar `rootflags=subvol=@` em `"user" -> "kernel_options"`. Ou seja, seu arquivo de configuração deve ficar parecido com isso:

```bash
cat /mnt/@/etc/kernelstub/configuration
```

<pre style="padding-top: 0;">
<code style="color: gray;">
{
  "default": {
    "kernel_options": ["quiet", "splash"],
    "esp_path": "/boot/efi",
    "setup_loader": false,
    "manage_mode": false,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  },
  "user": {
    "kernel_options": [
      "quiet",
      "loglevel=0",
      "systemd.show_status=false",
      "splash",
      "rootflags=subvol=@"
    ],
    "esp_path": "/boot/efi",
    "setup_loader": true,
    "manage_mode": true,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  }
}
</code>
</pre>

MUITO IMPORTANTE: Não se esqueça de colocar uma vírgula no final da linha acima de `"rootflags=subvol=@"`, que termina sem vírgula. Caso contrário, você receberá erros ao executar posteriormente update-initramfs(veja abaixo)!

### Ajustar a configuração do bootloader systemd

Assumindo que você utilizou a partição **/dev/sda1** como `EFI (/boot/efi)` (substitua _sda1_ pela partição que você utilizou, por exemplo, `nvme0n1p1`), precisamos ajustar algumas configurações para o gerenciador de inicialização do systemd também, então vamos montar nossa partição EFI:

```bash
mount /dev/sda1 /mnt/@/boot/efi
```

Adicione `rootflags=subvol=@` à última linha do Pop_OS-current.conf com o seguinte comando:

```bash
sed -i 's/splash/splash rootflags=subvol=@/' /mnt/@/boot/efi/loader/entries/Pop_OS-current.conf && cat /mnt/@/boot/efi/loader/entries/Pop_OS-current.conf
```

<pre style="padding-top: 0;">
<code style="color: gray;">
title Pop!\_OS
linux /EFI/Pop_OS-UUID_of_data-root/vmlinuz.efi
initrd /EFI/Pop_OS-UUID_of_data-root/initrd.img
options root=UUID=UUID_of_data-root ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@
</code>
</pre>

onde `UUID_of_data-root` é o UUID de `/dev/mapper/data-root`.

Opcionalmente, gosto de adicionar um tempo limite ao menu de inicialização do systemd para acessar facilmente a partição de recuperação:

```bash
echo "timeout 3" >> /mnt/@/boot/efi/loader/loader.conf && cat /mnt/@/boot/efi/loader/loader.conf
```

<pre style="padding-top: 0;">
<code style="color: gray;">
default Pop_OS-current
timeout 3
</code>
</pre>

### Crie um ambiente chroot e atualize o initramfs

Agora, vamos criar um ambiente chroot, que permite trabalhar diretamente dentro do sistema operacional recém-instalado, sem precisar inicializá-lo. Para isso, desmonte o sistema de arquivos raiz do btrfs em `/mnt` e remonte o subvolume `@` em `/mnt`:

```bash
cd / && umount -l /mnt && mount -o subvol=@,defaults,compress=zstd:1,discard=async /dev/mapper/data-root /mnt && ls /mnt
```

<pre style="padding-top: 0;">
<code style="color: gray;">
bin boot dev etc home lib lib32 lib64 libx32 media mnt opt proc recovery root run sbin srv sys tmp usr var
</code>
</pre>

Em seguida, os comandos a seguir nos colocarão em nosso sistema usando chroot (retirados da postagem de ajuda da System76 sobre [como reparar o bootloader](https://support.system76.com/articles/bootloader/#systemd-boot)):

```bash
for i in /dev /dev/pts /proc /sys /run; do mount -B $i /mnt$i; done && chroot /mnt
```

Agora estamos dentro do novo sistema, então vamos verificar se nosso fstab montou tudo corretamente:

```bash
mount -av
```

<pre style="padding-top: 0;">
<code style="color: gray;">
/boot/efi : successfully mounted
/recovery : successfully mounted
none : ignored
/ : ignored
/home : successfully mounted
</code>
</pre>

Excelente! Agora precisamos atualizar o initramfs para que ele esteja ciente das nossas alterações no kernelstub:

```bash
update-initramfs -c -k all
```

<pre style="padding-top: 0;">
<code style="color: gray;">
update-initramfs: Generating /boot/initrd.img-5.17.5-76051705-generic
kernelstub.Config : INFO Looking for configuration...
kernelstub : INFO System information:

    OS:..................Pop!\_OS 22.04
    Root partition:....../dev/dm-2
    Root FS UUID:........052ec665-cf5d-4372-bb65-1b82237b9101
    ESP Path:............/boot/efi
    ESP Partition:......./dev/sda1
    ESP Partition #:.....1
    NVRAM entry #:.......-1
    Boot Variable #:.....0000
    Kernel Boot Options:.quiet loglevel=0 systemd.show_status=false splash  rootflags=subvol=@
    Kernel Image Path:.../boot/vmlinuz-5.17.5-76051705-generic
    Initrd Image Path:.../boot/initrd.img-5.17.5-76051705-generic
    Force-overwrite:.....False

kernelstub.Installer : INFO Copying Kernel into ESP
kernelstub.Installer : INFO Copying initrd.img into ESP
kernelstub.Installer : INFO Setting up loader.conf configuration
kernelstub.Installer : INFO Making entry file for Pop!\_OS
kernelstub.Installer : INFO Backing up old kernel
kernelstub.Installer : INFO No old kernel found, skipping
</code>
</pre>

Observe que se você encontrar erros como este:

```bash
kernelstub.Config : INFO Looking for configuration...
Traceback (most recent call last):
File "/usr/bin/kernelstub", line 244, in <module>
main()
File "/usr/bin/kernelstub", line 241, in main
kernelstub.main(args)
File "/usr/lib/python3/dist-packages/kernelstub/application.py", line 142, in main
config = Config.Config()
File "/usr/lib/python3/dist-packages/kernelstub/config.py", line 50, in **init**
self.config = self.load_config()
File "/usr/lib/python3/dist-packages/kernelstub/config.py", line 60, in load_config
self.config = json.load(config_file)
File "/usr/lib/python3.9/json/**init**.py", line 293, in load
return loads(fp.read(),
File "/usr/lib/python3.9/json/**init**.py", line 346, in loads
return \_default_decoder.decode(s)
File "/usr/lib/python3.9/json/decoder.py", line 337, in decode
obj, end = self.raw_decode(s, idx=\_w(s, 0).end())
File "/usr/lib/python3.9/json/decoder.py", line 353, in raw_decode
obj, end = self.scan_once(s, idx)
json.decoder.JSONDecodeError: Expecting ',' delimiter: line 20 column 7 (char 363)
run-parts: /etc/initramfs/post-update.d//zz-kernelstub exited with return code 1
```

você provavelmente esqueceu uma vírgula no arquivo /etc/kernelstub/configuration [(veja acima)](#ajustar-a-configuração-do-kernelstub).

## 4° passo: Reinicialização, algumas verificações e atualizações do sistema

Agora, é hora de sair do chroot.

```bash
exit
```

Feche o terminal e, por fim, clique `Reboot Device` no aplicativo instalador. Cruze os dedos! Se tudo correr bem, após reiniciar você deverá ver um prompt de senha (EBA!), onde você insere a senha do luks e seu sistema deverá inicializar.

Agora, vamos clicar na tela de boas-vindas e verificar se tudo está configurado corretamente. Em um terminal execute:

```bash
sudo mount -av
```

<pre style="padding-top: 0;">
<code style="color: gray;">
/boot/efi : already mounted
/recovery : already mounted
none : ignored
/ : ignored
/home : already mounted
</code>
</pre>

Todas as entradas no `fstab` estão montadas corretamente.

```bash
sudo mount -v | grep /dev/mapper
```

<pre style="padding-top: 0;">
<code style="color: gray;">
/dev/mapper/data-root on / type btrfs (rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvolid=256,subvol=/@)
/dev/mapper/data-root on /home type btrfs (rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvolid=257,subvol=/@home)
</code>
</pre>

Nossas opções otimizadas de montagem do btrfs foram repassadas e estão sendo usadas corretamente. Observe que você não pode ter opções de montagem diferentes na mesma partição.

```bash
sudo swapon
```

<pre style="padding-top: 0;">
<code style="color: gray;">
NAME TYPE SIZE USED PRIO
/dev/dm-2 partition 4G 0B -2
</code>
</pre>

A partição swap criptografada está em uso.

```bash
sudo btrfs filesystem show /
```

<pre style="padding-top: 0;">
<code style="color: gray;">
Label: none uuid: 052ec665-cf5d-4372-bb65-1b82237b9101
Total devices 1 FS bytes used 6.33GiB
devid 1 size 47.39GiB used 8.02GiB path /dev/mapper/data-root
</code>
</pre>

```bash
sudo btrfs subvolume list /
```

<pre style="padding-top: 0;">
<code style="color: gray;">
ID 256 gen 79 top level 5 path @
ID 257 gen 79 top level 5 path @home
</code>
</pre>

Esses dois comandos btrfs nos informam qual disco está em uso e quais subvolumes estão disponíveis.

Se você instalou o POP!\_OS em um SSD ou NVME, habilite o `fstrim.timer`, pois [as opções de montagem `fstrim` e `discard=async` podem coexistir](https://www.phoronix.com/scan.php?page=news_item&px=Fedora-Btrfs-Opts-Discard-Comp):

```bash
sudo systemctl enable fstrim.timer
```

IMPORTANTE: Para que o trim do SSD funcione corretamente é importante adicionar discard ao crypttab [(veja acima)](#mudanças-no-crypttab). Verifique também se `issue_discards=1` está configurado em `/etc/lvm/lvm.conf` (deve ser definido como 1 por padrão):

```bash
cat /etc/lvm/lvm.conf | grep issue_discards
```

<pre style="padding-top: 0;">
<code style="color: gray;">
# Configuration option devices/issue_discards.
issue_discards = 1
</code>
</pre>

Se tudo estiver certo, vamos atualizar e aprimorar o sistema:

```bash
sudo apt update && sudo apt upgrade && sudo apt dist-upgrade && sudo apt autoremove && sudo apt  autoclean && flatpak update
```

Por fim, reinicie novamente.

## 5° passo: Instalar timeshift e timeshift-autosnap-apt

Instale o timeshift e configure-o diretamente pela GUI:

```bash
sudo apt install -y timeshift && sudo timeshift-gtk
```

- Selecione “btrfs” como “Tipo de instantâneo”; continue com “Próximo”
- Selecione a partição do sistema btrfs como “Local do Instantâneo”; continue com “Avançar”
- “Selecionar níveis de snapshot” (tipo e número de snapshots que serão criados e gerenciados/excluídos automaticamente pelo timeshift), minhas recomendações:
  - Ative “Mensal” e defina-o como 2
  - Ative “Semanal” e defina-o para 3
  - Ative “Diariamente” e defina-o para 5
  - Desativar “Por hora”
  - Ative “Boot” e defina-o como 5
  - Ative “Parar e-mails cron para tarefas agendadas”
  - continue com “Próximo”
  - Incluo o subvolume @home (que não é selecionado por padrão). Observe que, ao restaurar um snapshot com o Timeshift, você pode escolher se deseja restaurar @home também (o que, na maioria dos casos, você realmente não quer fazer!). Mas ter snapshots da minha pasta pessoal é bastante conveniente.
  - Ative “Habilitar qgroups BTRFS (recomendado)”. Há alguns problemas no GitHub que PODEM causar problemas de desempenho com isso (se você desativar as cotas manualmente também), mas eu nunca tive problemas, então sigo a recomendação de habilitá-lo.
  - Clique em “Concluir”
- “Crie” um primeiro snapshot manual, adicione um comentário “Instalação limpa” e saia do Timeshift

No terminal, você verá um `ERROR: can't list qgroups: quotas not enabled`. Simplesmente ignore, pois esse erro só ocorre na primeira vez que você executa o timeshift, por exemplo, executar `sudo timeshift --create` no terminal criara outro snapshot e você não verá mais esse erro.

Agora, o timeshift verificará a cada hora se snapshots ("horários", "diários", "semanais", "mensais", "de inicialização") precisam ser criados ou excluídos. Observe que os snapshots de "inicialização" não serão criados imediatamente, mas cerca de 10 minutos após a inicialização do sistema, usando um cronjob definido em `/etc/cron.d/timeshift-hourly` e `/etc/cron.d/timeshift-boot`.

Todos os snapshots são acessíveis a partir de `/run/timeshift/backup` (esta pasta será montada após a execução do Timeshift pela primeira vez após uma reinicialização do sistema). Convenientemente, a raiz da sua partição btrfs também é montada lá, facilitando a visualização, criação, exclusão e movimentação manual de snapshots, se necessário.

```bash
ls /run/timeshift/backup
```

<pre style="padding-top: 0;">
<code style="color: gray;">
@ @home timeshift-btrfs
</code>
</pre>

Observe que a pasta `/run/timeshift/backup/@` é sua `/` e `/run/timeshift/backup/@home` sua `/home`. Seus snapshots podem ser acessados ​​via timeshift-btrfs.

Agora, para também criar automaticamente snapshots ao atualizar nosso sistema (ou qualquer outra instalação do apt, como instalar ou remover aplicativos), vamos instalar o _timeshift-autosnap-apt_ do GitHub

```bash
sudo apt install -y git make && git clone https://github.com/wmutschl/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt && cd /home/$USER/timeshift-autosnap-apt && sudo make install
```

Depois disso, faça alterações no arquivo de configuração:

```bash
sudo nano /etc/timeshift-autosnap-apt.conf
```

Por exemplo, como não temos uma partição `/boot` dedicada, podemos definir `snapshotBoot=false` no arquivo `timeshift-autosnap-apt.conf` de forma que o diretório `/boot` não seja sincronizado com `/boot.backup`. Observe que a partição EFI será sincronizada com `/boot.backup/efi`. Portanto, se algo der errado com a partição EFI, você sempre terá um backup dela também. Além disso, o POP!\_OS não usa o GRUB, então podemos definir `udateGrub=false`.

Verifique se tudo está funcionando:

```bash
sudo timeshift-autosnap-apt
```

<pre style="padding-top: 0;">
<code style="color: gray;">
Rsyncing /boot/efi into the filesystem before the call to timeshift.
Using system disk as snapshot device for creating snapshots in BTRFS mode
/dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
Creating new backup...(BTRFS)
Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2022-05-24_11-15-25
Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2022-05-24_11-15-25/@
Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2022-05-24_11-15-25/@home
Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2022-05-24_11-15-25/info.json
BTRFS Snapshot saved successfully (0s)
Tagged snapshot '2022-05-24_11-15-25': ondemand
</code>
</pre>

Agora, se você executar sudo apt install|remove|upgrade|dist-upgradeo timeshift-autosnap-apt, ele criará um instantâneo do seu sistema com timeshift .

## 6° passo: Pratique a recuperação e a reversão do sistema

Agora, vamos praticar o que fazer em caso de desastre no sistema. Observe que acabamos de criar snapshots para os quais podemos sempre reverter. Então, como exemplo, vamos excluir nossa pasta `/etc`, o que, claro, você nunca deve fazer:

```bash
sudo rm -rf /etc
```

Agora tente reiniciar e você notará que o processo de inicialização obviamente trava porque o sistema está com defeito. Então, inicialize no Sistema de Recuperação do POP!\_OS. Em seguida, acesse o Gerenciador de Arquivos e a seção "Outros Locais". Selecione o disco criptografado e digite sua senha do LUK para descriptografá-lo. Observe que isso monta a raiz de nível superior do seu sistema, então você pode acessar diretamente os arquivos quebrados e movê-los de volta ou simplesmente usar o Timeshift para reverter. Mostrarei as duas abordagens.

### Reverter com timeshift

Instale o timeshift pelo Centro de software ou usando o terminal:

```bash
sudo apt install timeshift
```

Abra o Timeshift, selecione BTRFS e seu disco e você verá os snapshots que criamos. Selecione um e clique em `Restore`. O Timeshift renomeará e moverá sua subpasta atual quebrada `@` substituindo-a pelo snapshot que você acabou de selecionar. Reinicie e tudo voltará ao normal! Fácil, né?!

### Reverter manualmente

Assumindo que a pasta montada é `052ec665-cf5d-4372-bb65-1b82237b9101`, abra um terminal e vá para a pasta.

```bash
cd /media/recovery/052ec665-cf5d-4372-bb65-1b82237b9101 && ls
```

<pre style="padding-top: 0;">
<code style="color: gray;">
@ @home timeshift-btrfs
</code>
</pre>

O nome da pasta é baseado no UUID do dispositivo montado. Em seguida, mova o subvolume quebrado para longe:

```bash
sudo mv @ @.broken
```

Encontre o snapshot que você deseja reutilizar na pasta `timeshift-btrfs/snapshots/`

```bash
ls timeshift-btrfs/snapshots
```

<pre style="padding-top: 0;">
<code style="color: gray;">
2022-05-25_13-12-45 2022-05-25_13-13-48 2022-05-25_13-17-17
</code>
</pre>

Por exemplo, quero reverter para o mais recente de 2022-05-25_13-17-17. Para fazer isso, crie um snapshot do subvolume `@` que está dentro desta pasta, chame-o `@` e crie-o no nível superior:

```bash
sudo btrfs subvolume snapshot timeshift-btrfs/snapshots/2022-05-25_13-17-17/@ @
```

<pre style="padding-top: 0;">
<code style="color: gray;">
Create a snapshot of 'timeshift-btrfs/snapshots/2022-05-25_13-17-17/@' in './@'
</code>
</pre>

```bash
ls /media/recovery/052ec665-cf5d-4372-bb65-1b82237b9101
```

<pre style="padding-top: 0;">
<code style="color: gray;">
@ @.broken @home timeshift-btrfs
</code>
</pre>

Resumindo, substituímos o subvolume `@` quebrado por um em bom estado. Reiniciamos e tudo voltou ao normal! Fácil, né?!

Se tudo correr bem e você estiver de volta ao seu sistema, você deve excluir o instantâneo usando o comando abaixo para economizar espaço.

```bash
btrfs subvolume delete @.broken
```

TERMINADO! PARABÉNS E OBRIGADO POR PERSISTIR!

Confira meus passos pós-instalação do Pop!\_OS .

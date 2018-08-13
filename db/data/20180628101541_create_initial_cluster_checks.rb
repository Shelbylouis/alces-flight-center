class CreateInitialClusterChecks < ActiveRecord::Migration[5.2]
  def up
    cluster = Cluster.find_by_name!('Demo Cluster')

    general_category = CheckCategory.create!(
      name: 'General'
    )

    general_checks = [
      {
        name: 'Check connectivity (login)',
        command: 'ssh <login node>'
      },
      {
        name: 'Check controller messages logs',
        command: 'less /var/log/messages'
      },
      {
        name: 'Check controller uptime/reboots',
        command: 'uptime'
      },
      {
        name: 'Check controller disk space',
        command: 'df -h'
      },
      {
        name: 'Check controller memory',
        command: 'free -m'
      },
      {
        name: 'Check backups complete on masters',
        command: '/root/check_dirvish'
      },
    ]

    create_checks(general_checks, general_category)

    master_category = CheckCategory.create!(
      name: 'Master Nodes'
    )

    master_checks = [
      {
        name: 'Check messages log on master nodes',
        command: 'less /var/log/messages'
      },
      {
        name: 'Check master HA pair status',
        command: 'crm_mon -1'
      },
      {
        name: 'Check disk space available (local)',
        command: 'df -h'
      },
      {
        name: 'Check IPMI on masters',
        command: 'ipmitool -c sel elist'
      },
      {
        name: 'Check master uptime/reboots',
        command: 'uptime'
      },
      {
        name: 'Check memory/swap usage',
        command: 'free -m'
      },
    ]

    create_checks(master_checks, master_category)

    storage_category = CheckCategory.create!(
      name: 'Storage'
    )

    storage_checks = [
      {
        name: 'Check messages logs on storage nodes' ,
        command: 'less /var/log/messages'
      },
      {
        name: 'Check particularly for Lustre/BeeGFS messages',
        command: 'less /var/logs/messages'
      },
      {
        name: 'Check disk space available (local)',
        command: "pdsh storage 'df -h/' - 'df -h /tmp'"
      },
      {
        name: 'Check user filesystems',
        command: 'df -h /users'
      },
      {
        name: 'Check parallel filesystem (Lustre) capacity on login node',
        command: 'lfs df -h'
      },
      {
        name: 'Check parallel filesystem (Lustre) inodes on login node',
        command: 'lfs df -i'
      },
      {
        name: 'Check data1',
        command: 'df -h /mnt/data1'
      },
      {
        name: 'Check data2',
        command: 'df -h /mnt/data2'
      },
      {
        name: 'Check service filesystems - gridware',
        command: 'df -h /opt/gridware'
      },
      {
        name: 'Check service filesystems - apps',
        command: 'df -h /opt/apps'
      },
      {
        name: 'Check service filesystems - service',
        command: 'df -h /opt/service'
      },
      {
        name: 'MONTHLY ONLY - Check users with significant storage use',
        command: 'screen cd /users && du -h --max-depth=1'
      },
      {
        name: 'Check processes sanity',
        command: 'top / ps -ef'
      },
      {
        name: 'Manually check disk status in arrays',
        command: '/opt/MegaRAID/MegaCli/MegaCli64 -ldinfo -lall -aall'
      },
    ]

    create_checks(storage_checks, storage_category)

    infra_category = CheckCategory.create!(
      name: 'Infra Nodes'
    )

    infra_checks = [
      {
        name: 'Check messages logs on headnodes',
        command: 'less /var/log/messages'
      },
      {
        name: 'Check headnode memory/swap usage',
        command: 'free -m'
      },
      {
        name: 'Check processes sanity',
        command: 'ps -ef / top'
      },
    ]

    create_checks(infra_checks, infra_category)

    login_category = CheckCategory.create!(
      name: 'Login Nodes'
    )

    login_checks = [
      {
        name: 'Check message logs on logins',
        command: 'less /var/log/messages'
      },
      {
        name: 'Check users logged into user-facing nodes',
        command: 'w'
      },
      {
        name: 'Check login load & reboots',
        command: 'uptime'
      },
      {
        name: 'Check login memory/swap usage',
        command: 'free -m'
      },
      {
        name: 'Check logins for user workload',
        command: 'top'
      },
      {
        name: 'Check /tmp partition space available',
        command: 'df -h /tmp'
      },
      {
        name: 'Check disk space available on logins',
        command: 'df -h'
      },
      {
        name: 'Check procceses sanity',
        command: 'top / ps -ef'
      },
    ]

    create_checks(login_checks, login_category)

    computes_category = CheckCategory.create!(
      name: 'Computes'
    )

    computes_checks = [
      {
        name: 'Check compute IPMI for any messages',
        command: "metal ipmi -g comput -k 'sel elist'"
      },
      {
        name: 'Compute load (procs vs load)',
        command: "pdsh -g compute 'uptime'"
      },
      {
        name: 'Check compute local disk space',
        command: "pdsh -g compute 'df -h /' - 'df -h /tmp'"
      },
      {
        name: 'Check compute for non-scheduled jobs',
        command: 'ps -ef'
      },
      {
        name: 'Check zombie processes',
        command: 'top'
      },
    ]

    create_checks(computes_checks, computes_category)

    scheduler_specific_category = CheckCategory.create!(
      name: 'Scheduler Specific'
    )

    scheduler_specific_checks = [
      {
        name: 'Check queue for errored jobs',
        command: 'squeue'
      },
      {
        name: 'Check host list has all nodes present',
        command: 'sinfo -Nl'
      },
      {
        name: 'Check queue for bad jobs causing issues',
        command: nil
      },
      {
        name: 'Check for any disabled nodes',
        command: nil
      },
      {
        name: 'Check number of jobs queued',
        command: nil
      },
      {
        name: 'Check number of jobs running',
        command: nil
      },
    ]

    create_checks(scheduler_specific_checks, scheduler_specific_category)

    ganglia_category = CheckCategory.create!(
      name: 'Ganglia'
    )

    ganglia_checks = [
      {
        name: 'Check all nodes are reporting metrics',
        command: 'http://flightcenter-ganglia/ganglia/?c=<cluster>'
      },
      {
        name: 'Check for high memory usage',
        command: 'http://flightcenter-ganglia/ganglia/?c=<cluster>'
      },
      {
        name: 'Check for high swap usage',
        command: 'http://flightcenter-ganglia/ganglia/?c=<cluster>'
      },
      {
        name: 'Check for any high temperatures/hot spots in logs',
        command: 'http://flightcenter-ganglia/ganglia/?c=<cluster>'
      },
      {
        name: 'Check overall cluster load',
        command: 'http://flightcenter-ganglia/ganglia/?c=<cluster>'
      },
    ]

    create_checks(ganglia_checks, ganglia_category)

    nagios_category = CheckCategory.create!(
      name: 'Nagios'
    )

    nagios_checks = [
      {
        name: 'Check for any alerts',
        command: 'http://flightcenter-nagios/nagiosxi'
      },
      {
        name: 'Check for any disabled alerts',
        command: 'http://flightcenter-nagios/nagiosxi'
      },
      {
        name: 'Report any current alerts',
        command: 'http://flightcenter-nagios/nagiosxi'
      },
      {
        name: 'Record any comments in Nagios',
        command: 'http://flightcenter-nagios/nagiosxi'
      },
    ]

    create_checks(nagios_checks, nagios_category)

    Check.find_each do |check|
      ClusterCheck.create!(
        cluster: cluster,
        check: check
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def create_checks(category_checks, category)
    category_checks.each do |check|
      Check.create!(
        check_category: category,
        name: check[:name],
        command: check[:command]
      )
    end
  end
end

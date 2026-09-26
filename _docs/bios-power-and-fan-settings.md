# Recommended UEFI power and fan settings

[日本語](bios-power-and-fan-settings.ja.md)

This guide is a starting point for an ASUS TUF GAMING Z890-PLUS WIFI with an Intel Core Ultra 7 270K Plus and a DeepCool AK620 DIGITAL SE. It is **not a record of the machine's current UEFI settings**. Confirm available options in the installed BIOS version before changing them.

The goal is to reduce abrupt fan noise while preserving cooling and using Intel's standard CPU limits as the UEFI baseline. The Linux `agent` power profile is applied separately and only when explicitly requested.

## CPU power and voltage

| UEFI option | Recommended starting point | Reason |
| --- | --- | --- |
| Performance Preferences | `Intel Default Settings`; choose `Performance` if prompted | Use the processor's standard limits rather than an ASUS overclocking profile. |
| ASUS MultiCore Enhancement | `Disabled - Enforce All limits` | Avoid removing CPU power limits. |
| AI Overclocking, core ratios, SVID Behavior, load-line calibration | Disable automatic overclocking; leave manual ratios and voltage-related tuning at `Auto` | Fan-noise reduction does not require raising voltage or clocks. |
| Unlimited ICCMAX | Leave disabled or at the Intel-default behavior, if offered | Do not remove current limits to reduce noise. |
| Long/Short Duration Package Power Limit (PL1/PL2) | Leave at the Intel-default profile rather than forcing the Linux `agent` values in UEFI | Preserve a known baseline and keep profile changes explicit in Linux. |

Intel lists **125 W Processor Base Power**, **250 W Maximum Turbo Power**, and **105°C maximum operating temperature** for this CPU. These are specifications, not a measured UEFI configuration or a target operating temperature. Avoid treating the previously reported 200 W PL1 as Intel's default.

## Q-Fan cooling

1. Check that the CPU cooler is connected to `CPU_FAN` and that both cooler fans spin. Keep the CPU fan speed warning enabled; do not use fan stop on the CPU cooler.
2. Select `PWM` for a confirmed four-pin fan connection, or use `Auto` if the fan wiring is uncertain. Run Q-Fan Tuning to determine the installed fans' usable speed range.
3. Start with the `Standard` CPU fan profile. If brief temperature spikes make the fan surge, try a CPU fan **Step Up Time around 2–3 seconds**, only if that option and those values are available. Do not delay the response to sustained high temperatures.
4. Adjust the lower part of the CPU fan curve only after confirming a stable minimum RPM. Keep a sufficiently steep rise at higher temperatures; do not flatten the entire curve or disable the high-temperature fan response.
5. Check case-fan airflow under sustained load. A quieter CPU fan must not leave heat trapped around the CPU cooler or other components.

Q-Fan option names and available step-up intervals can vary by BIOS version. The suggested 2–3 seconds is a **trial value**, not an ASUS-prescribed setting or a guarantee that noise will disappear.

## Apply and check

1. Note the original UEFI values, change one group of settings at a time, then save and reboot.
2. Run a representative agent/build workload for about 15–30 minutes. Check CPU temperature, stable fan rotation, noise, and task completion time.
3. If temperature keeps climbing, cooling becomes inadequate, or the CPU fan stalls, restore the fan curve or increase airflow. Sustained temperatures around **80–85°C** are a conservative point to re-evaluate the curve, **not** Intel's thermal limit.
4. If desired, apply the separate Linux profile with `make cpu-power-agent` and inspect it with `make cpu-power-status`. UEFI fan settings and Linux power limits address different parts of the problem.

## Sources

- [ASUS TUF GAMING Z890-PLUS WIFI manual downloads](https://www.asus.com/motherboards-components/motherboards/tuf-gaming/tuf-gaming-z890-plus-wifi/helpdesk_manual/) and the [Intel 800 Series BIOS manual](https://dlcdnets.asus.com/pub/ASUS/mb/13MANUAL/E25827_Intel_800_Series_BIOS_manual_EM_WEB.pdf?model=TUF+GAMING+Z890-PLUS+WIFI): Q-Fan Control, Performance Preferences, ASUS MultiCore Enhancement, and power limits.
- [ASUS CPU fan detection guidance](https://www.asus.com/support/faq/1006064/): CPU_FAN connection and low-speed warnings.
- [Intel Core Ultra 7 270K Plus specifications](https://www.intel.com/content/www/us/en/products/sku/245692/intel-core-ultra-7-processor-270k-plus-36m-cache-up-to-5-50-ghz/specifications.html): power and temperature specifications.

<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Get-PendingRebootNotificationRemediation
Description:
Remediation script to display toast notification for pending reboot
Release notes:
Version 1.0: Init
#> 

#https://www.systanddeploy.com/2022/04/toast-notification-to-notify-users-when.html
Function Register-NotificationApp($AppID,$AppDisplayName) {
    [int]$ShowInSettings = 0
    [int]$IconBackgroundColor = 0
	
	$iconUri = "C:\Windows\ImmersiveControlPanel\images\logo.png"
    $appregPath = "HKCU:\Software\Classes\AppUserModelId"
    $regPath = "$appregPath\$AppID"
	$notificationsReg = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
	If(!(Test-Path -Path "$notificationsReg\$AppID")) 
		{
			New-Item -Path "$notificationsReg\$AppID" -Force
			New-ItemProperty -Path "$notificationsReg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
		}

	If((Get-ItemProperty -Path "$notificationsReg\$AppID" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') 
		{
			New-ItemProperty -Path "$notificationsReg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
		}	
		
    try {
        if (-NOT(Test-Path $regPath)) {
            New-Item -Path $appregPath -Name $AppID -Force | Out-Null
        }
        $DisplayName = Get-ItemProperty -Path $regPath -Name DisplayName -ErrorAction SilentlyContinue | Select -ExpandProperty DisplayName -ErrorAction SilentlyContinue
        if ($DisplayName -ne $AppDisplayName) {
            New-ItemProperty -Path $regPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force | Out-Null
        }
        $ShowInSettingsValue = Get-ItemProperty -Path $regPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
        if ($ShowInSettingsValue -ne $ShowInSettings) {
            New-ItemProperty -Path $regPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force | Out-Null
        }
		
		New-ItemProperty -Path $regPath -Name iconUri -Value $iconUri -PropertyType ExpandString -Force | Out-Null	
		New-ItemProperty -Path $regPath -Name IconBackgroundColor -Value $IconBackgroundColor -PropertyType ExpandString -Force | Out-Null		
		
    }
    catch {}
}

#https://github.com/damienvanrobaeys/Intune-Proactive-Remediation-scripts/blob/main/Recycle%20Bin%20size%20alert/RecycleBin_Size_Remediation.ps1
Function Create-Action
	{
		param(
		$Action_Name		
		)	
		
		$Main_Reg_Path = "HKCU:\SOFTWARE\Classes\$Action_Name"
		$Command_Path = "$Main_Reg_Path\shell\open\command"
		$CMD_Script = "C:\Users\Public\Documents\$Action_Name.cmd"
		New-Item $Command_Path -Force
		New-ItemProperty -Path $Main_Reg_Path -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
		Set-ItemProperty -Path $Main_Reg_Path -Name "(Default)" -Value "URL:$Action_Name Protocol" -Force | Out-Null
		Set-ItemProperty -Path $Command_Path -Name "(Default)" -Value $CMD_Script -Force | Out-Null		
	}
	

#Encode the image in base64: https://www.base64-image.de/
$tostImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAyoAAAImCAYAAAC8fH4IAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bS0UqghaU4pChOlkQFdFNqlgEC6Wt0KqDyaVf0KQhSXFxFFwLDn4sVh1cnHV1cBUEwQ8QRycnRRcp8X9JoUWMB8f9eHfvcfcO8DYqTDG6xgFFNfVUPCZkc6tC4BV+hNGPQcyKzNAS6cUMXMfXPTx8vYvyLPdzf45eOW8wwCMQzzFNN4k3iKc3TY3zPnGIlUSZ+Jx4TKcLEj9yXXL4jXPRZi/PDOmZ1DxxiFgodrDUwaykK8RTxBFZUSnfm3VY5rzFWanUWOue/IXBvLqS5jrNYcSxhASSECChhjIqMBGlVSXFQIr2Yy7+sO1PkksiVxmMHAuoQoFo+8H/4He3RmFywkkKxgD/i2V9jACBXaBZt6zvY8tqngC+Z+BKbfurDWDmk/R6W4scAX3bwMV1W5P2gMsdYOhJE3XRlnw0vYUC8H5G35QDBm6BnjWnt9Y+Th+ADHW1fAMcHAKjRcped3l3d2dv/55p9fcD0XVyzQk53s4AAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQfmBRoSGQEIKIQkAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAIABJREFUeNrs3XecHHXh//H3bL3ee8qlX3oFAiFACAGlFwtCEMWCCBYsKAgo/uwonS+CiihFEaV3aZESCIEkpPeQdrlcv73bvd293ZnfH5ccuezs9Vx9PR+PPOBmZmdmZ3buPu/9NMOyLGtSyUQBANDb5h47V7+7+WYuBAAghoOQAgAAAKDfBRUuAQAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAACCCgAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAEEFAAAAAAgqAAAAAAgqAAAAAEBQAQAAAEBQAQAAAACCCgAAAAAQVAAAAAAQVAAAAACAoAIAAACAoAIAAAAABBUAAAAABBUAAAAAIKgAAAAAIKgAAAAAAEEFAAAAAAgqAAAAAAYYF5cAAIDBybIsmaapYDCoyspK1dXVKRwOy7IsLg7QTQ6HQx6PR5mZmcrOzpbX65XDQR0AQQUAALQpGo2qtrZWpaWl2rNnjzZs2KAtW7aopqaGsAL0UEjJyclRSUmJJkyYoBEjRmjYsGFKSUkhsBBUAACAnUgkoj179uijjz7SBx98oDVr1sjn87XahqACdJ1hGJKksrIyrV27VllZWZo9e7aOPvpoTZ06VXl5eXK5KGYTVAAAQIumpibt3LlT//vf/7RkyRLt3btXlmXJMAxFo1GZpimXyy2PxyOXyyWHw+CiAR1kmqaamiIKNzUpGonI6XTK4XCourpar7/+urZt26ZFixbp+OOPV1FRkdxuNxeNoAIAAKLRqEpLS7VkyRK9/PLLqqqqalXAyshIV1FhobKzs5SWlqbExEQ5nU4uHNBBkUhEjYGA6nw+VVZWaV/Zfvl8PjkcDlmWpR07dujpp5+WJJ1yyinKycnhGSOoAACAmpoaLV++XP/73/9UWVkpwzBkWZaSEhM1YcI4TZs2VePHj1dmZoYSExLkdrvlpC090PEvA0xT4XBYwcZGVVZVa9OmzVq9Zq22b9+hYCgkwzBUWVmp119/XTk5OZo3b56Sk5NbmoqBoAIAwJDT1NSk3bt3691339XevXtblufl5eqYo+Zo7txjNH78OOVkZ8vr9cjhcMgwDApQQCdYltUyml5jY1Djx4/V+PFjtWzZcn2wYqWqq2skqaX55ejRozV69Gj6qxBUAAAYuoWnuro6bdy4Udu2bZPU3Nk3JztLC08+SSfOP17jxo1VWloawQToIR6PR6mpKcrOylJ2VpaSkpL05tvvqLq6RtFoVJs2bdLatWtVVFREUOki6nsBABgEQaW2tlabN29WIBCQJCUlJemYY47SSSeeoIkTS5Senk5IAXqY0+lUZmampk6dopNOOkGzZ81QUlKiJMnv92vNmjXy+/0yTZOLRVABAGDoiUQi8vl8qqysVDQalcPhUPHIETp27lwVjyqWy+NROBJRlMIS0ONfEhiGoZSUFJVMmKCj5szRyBEj5HA4FIlEVF1draqqKkWjUS4WQQUAgKFXUIpEIvL7/aqvr5dlWfJ43JoydYqGjRyhsGWpwlevSl+96gIBhZqaxAwqQM8yDEMZGemaNLFEEyaMV2JCgizLUiAQUFVVFTUqXUSDOQAABkFYaWpqUiQSkWVZSk1L0/BRxYq4XKqob1DENGUYhrwup9KTkpSVkqJEj4cLB/Qgp9OpwsICjR5VrNS0VDUGg4pEIgqFQkywSlABAIDA4nA4lJmTLU9KsoLRqAzLaqlBiUSjikRNmZal3NRUed1u+q0APSgpOVm5ubnKSE9XRUVlyyhh6BqafgEAMIgYhqH0jAw5XO6WgGIc+GdZlkKRiKobGlRZX69gOMwFA3qyYG0YSk1JUWpqihzMUdRt1KgAADDIgkpCGzPOW5alcCSq6ga/LMtSjgwleKhZAXqKN8ErrzeBZ4qgAgAADudwOmU44heSWmpW/H7JkrLTUpXo8VCwArr/TYEcDoecTmpTeuR3GZcAAIBBVlY67L/xwko4ElW1369KX70aw2Ha0gM98OwZIvATVAAAQLdYlqVwNKoav1+V9YQVAP0LTb8AACCsqLrBL0nKSU1VgscjB83AAPQxalQAACCsqOmw0cCoWQFAUAEAAH0fVqSW0cAO9lkxCSsA+hBNvwAAGFS612QrHImoqqFBlizlpKYq0eulGRgAggoAAOgBliF1ozKk6ZA+K9mSkggrAAgqAACgP2iKRlXT4JclKVeiZgUAQQUAAPQP4QNhRZaUk0bNCgCCCgAA6CeaDsyzIkk5qVJSAmEFAEEFAAD0o7BiWZZylKrkhATCCgCCCgAA6CRD3R38yzas1AYCLQdIpmYFAEEFAAB0Jav0tEPDiqVUpVCzAoCgAgAA+oODYcU6EIZ6shnY3/7+kL5z9Q/irp9//Dw998wTcjjs56u2LEsXX/IlPf/CS3H38fOf3aDvXf2duOsty9L27Tu0YuUqrVy5Stu2b9eu3bs1a+ZMjR0zRscdN1fTpk1VakpK3H08/Mg/dOW3rrZdl5ycrEmTSjR82DCVTJigCRPGa/KkiSopmSCXy9Wt69MRvpryds/xcFOmTNLEkhJNmjhR06ZN0ZzZs5SXl9ep9/7U449p4cIFcY9x4UWX6MWX/tvy88oP3tPYsWN44AgqAAAAnQsrdYGADk7W0twMzHHEj/v2O0u1Z+9ejRwxwnZ96b59bYaU9pTt36/77vuLbrntjph169ZtaPn/iSUTdOstN+v4ecfJ6GRI8/v9+uCDFfrggxWtlp95xqf1k2t/pGnTpva7+71u3YZW71+SHrj/Pp1/3rlxQ+Ph/t8vf61jjjlKKW0EPOBwDi4BAADoWlhpVIXPp4ZgSKZl9cpxN2zY2GaBuqu2b9+hc879jG1IOdzGTZt1xlnn6eFH/tlj7+v5F17S8Scu1DPPPDcg7v9lX/2G/vXYvzu8/YqVq/Tscy/w4ICgAgAAei+sVPp88geDvRJW3nzr7bjr3nhjSZf2WbZ/vy697GvauGlzp1531bev1iuvvtaj7++SL31FL//3lQFx/7/xzW9r69ZtHd7++z/8sfbvL+fBAUEFAAD0Tlip9QdUXncgrJhmj+173nFzVVw8stWyu+7+o+obGmK2ravz6f/+eF+rZZ86bVG7xzBNU3f/3x+1evWaVsuLi0fq+Wef1L49O1RdUap1q1foe9/9dszrv/3d76uysqrd4/zh5t/IV1MuX025Kvfv0eaNa/Tg3+6PeX+S9LkLF2vL1q0dCzaLL2rZb0f+tRk8Lv9qzPZV5Xu1fct6/e43v7R9zXPPd7yWxO/392gtFAgqAAAAbYqYpuoCzWGlIRjqsbCSl5enr3z50pjlW7fEFuI3bdrU6ufPf+4zmnfcse0eY9VHq3XnXffELH/kwQd0wvzjlZycLJfLpREjhusn1/1IX7jwc622Ky3dp8f+/Xin3pfH41FBfr7OO/dsPfvU4xpn02n8V7/6nSKRSJ/fW7fbrZycHF3+9a/qksUXxax/8KFHFO3E/f75L36lzZu38NCAoAIAAHo3rLT0WemhsDJ37jExy1au+ihm2bL3l7f6+cwzPt2h/T/99LMxy777nas0ffq0mOVer1dXXP61mOW/+NVvVFfn69L7GzWqWL+/+Tcxy5946mktX/5hv7m/TqdTn/7UabGhcdt2BRuDndrXH+/7c6fCDQgqAABgELH64JgR01TtIWGlJwqjJRMmxCz7z+NPtgpC4XBYD/ztwVbbdGT0rOrqat12x10xy+0K5AdNnjxZycnJrZb5/X6tWLmyy+/xhPnH66ijZscsf/7FF/vVZ6qpKRyzLCcnWwmJCXFfU1RUGLPs/r/+TcuXf8BDCoIKAADoPdFWYSXY7bCSnZ0V0+To7XeWas+evS0/b9+xQ1u3bW/5efasmRpVXNzuvnft3mO7vK3XJiR49cVLLo5ZvmbN2i6/R4/Ho8UXfSFm+Z133aOGBn+/uK+hUMi2idv5554jZxtDFN/wk2s1ZcqkmOW//8OtCgZDPDAgqAAAgD4IK3U9E1Y+fdqpMcvWHzJM8apVq1utu/iiC9udPFGSdu7cabs8MzOjzdeNHTM6ZtlLL3dvpK7Zs2baLi+vaLsD/MOP/FNpmXlt/nvs3//p0jlZlqVQKKTdu/fo93+4rdWEjAdd+PnPtrmPtLQ0/fxnP41Z/sqrr+vV117jYQFBBQAA9H5YqWtsVEWdT/XdDCtTpk6OWfbmm2+1FKaffOrpVuuOmjO7Q/utqam1XZ6UlNTm67KysmKWvf3OUoWbmrr8Hu32KUm1tXW9ds/u+9P9rQJOela+cgtGaMr02br5D7fGbH/TT2/QnHaudTQa1YKTTtA5Z58Zs+6nP/t/qqmt5WEBQQUAAPRBWDlQs1Lf2NjlsFI8cmRMjcPd99yr+oYGlZbui/mmf8KE8R3ar88X2wHerhP94bwej+3yUDDY5Wt1eL+Xg4Ld2OeRdOftt+hb3/qmnE5nu9t6PB59/+rvxCzfum27Hn/8SR4UEFQAAEAfhBXLku9gzUqga2HF5XLFDAssNQ9TvG79+lbLvvfdbyslJaVjhSCbQnY02oEhgQ3jCFwp++EPOhIEetuyd9/Ul7/0RXnc7g6/ZtasmfrWlVfELP/+D3+sXbt3y+GgSAqbZ59LAAAAjmhYMU35gkFZB4rjaYkJnS6AH3XUnJhlK1au0pbD5lQ56cQTOrzP9LS0mGXr1m2QZVky2ggj4bB9J3BvQkKXr1Eg0Gi7PLmdZmiXLL5I99x9R6/ez640RzMMQ1//+ld09z33xqx74IEHlZmZyYOC2C8TuAQAAAw2Vr87o6hpqr6xUZU+n3xdaAY2Yfy4mGV/+esDuufeP7VaNmnyxA7vMysrs1Oh4aDq6hqbIDW7UzUMhyvbv992eZpNmDpSDp+ZvnzfLtvJKJ9/oWvDJo8eNcp2hvtbbrtDTz71DI8tCCoAAAyFkGL0wzOLWpZ8waAqfPXyBQKdCitpaWm68orLWy1bt25Dq5/POftMFRYUdHif8YYhrm2ng/f27Ttilp15+undujYffbQ6Zllx8UgVFhb02f1KSEjQNw+75lLzsMnl5eVd2ueFn/+s7dwqfr+fRxcEFQAA0IdhxTRVHwyq/EBYiUSjHX7tggUntbn+nLPP6tS5jBw5wnb5x3GGLZaa5xP5+0OPxCyfNm1Kl6+J3x/Qn//y15jllyy+SO5u1NL0hPnz59kuf7+LEzZmZWXZ1qoABBUAANAvwkrDwZqVxsYOh5XJ7TTrmjFjWqfOIzU1VTf99IaY5S+9/N+4r1m3foPtt//x5kHpiFdefU0bN22OWX7G6Z/u83s1ftw4zT8+Nqw88o9HZXZxFLfTTl2kkxecyIMAggoAAOifYaX+0LBith9Whg8bphNPmG+7bmLJBI0ePbrT53H6p0+LWXbHnf+n1avXxCwPh8O6709/iVn+k+t+pJycnC5dh7Xr1uvSL381ZvlFX/i8pkye1Of3yeVy6ctfuiRm+fMvvKSt27Z1aZ+JiYn68TU/4CEAQQUAAPTfsNJcs+KTL9Ao02r7G3qHw6HPfuZ823WXXnpJlzqzT5o0Udf/5Mcxy7/8la/r7beXyu/3KxKJaM+evfrNb3+vfz76WKvtkpOTdekXF3fqmOFwWKX79unf/3lC8+YviFmfnJys6669pt8M2Tv3mGNsl7/55ttd3+fcY/SlSy/hIUDbQZlLAAAA+jKs1B+Y1DAQbn9m93hNrI45+qgun8PXvvJlvfHGEi19d1nLsq3btuuMs89r97V/uvduFRUWtrvdD390nX74o+s6dD4P/e3+uB39D/fwI//Uw4/8s8Pv1VfT+U7wI0eO0GcuOE+PP/FUq+X3/PE+Lb74C0pMTOz0Pp1Op6668hv6+4MP8xAg/pcTXAIAAAYTQ/1zzK/4TNNSfTCo+sbGdrcdN26s7SzuJRMmdPn42dnZuu+P/6eJJZ3bx1133KqzzjyjR6/FU48/pkWLFvavT5Rh6POf+0zM8q3btmv1mrVd3u/EkhLdeP11PLIgqAAAMGSiijHwztk0LYWa2q9RSUpKihmm+MorLld6evfmGykuHqlnn35C3/3OVe1uO3vWTL3w3FP64iUXtzkxZGdc8Y2va9WHy7Rw4YJ+eX/mzJ5lu/yFF17q1n6/eMnFtsETkGj6BQDAIEspA/fULav1RJWmZcmyeUvz58/T72+5reXnk08+qUeOn5+fp5//7EZdeslivb/8A6366CNt2LBJDQ0Nmjp1siaMH6+5c4/R1CmTu1W4Li4eqTmzZmnUqGLNnDlD06ZN0ehRo/pNnxQ7eXl5uvKKy2Mm2Lztjrv0rauuUG5ubpf2W1CQr1v/8Ft945vf5tlF7K+ziRNKLC4DAKAvzD12rn53881ciG4W7gOBgJYtW6b7779f5RUVOvGUkzV/4QLl5OXJcAy8xhMOw1Cy16u89DSlJyXJ6XQO5PyFIcQ0Ta1du16P/PNRvfve+yosLNTixYs1f/58JSQkcIE6iRoVAADQvwp7lqWGUEiq80mWlJacJBdhBRhy6KMCAAD6Hcuy5A+FVO7zqc7fPIM9TUCAoYUaFQAA0C+ZB8KKfD5JltKTk6lZ6QH7G0ytrYhobY2p9X5LO8OWvIY0yuvQyARpRqZDJdkujUjn+2wQVPrcA3//m3Jzc2Xwqw/AEWbJUkVFhS770pe5GDhSH7IBrTbs1o17483yHpIkeQwpzyllOg0VJxgameTQmDRD4zKdKkztWOF6f4Opc94N9th5j3IZ+jhif/HPSHPoZ3M71j8hFLH0qSWNajxsV3dMcmtsplNnLbU/5wdmeDU5z9nmvssaTP1jU1j/qrafWLMsYOq9gPRYtSlti+gzmYYuHu/R8HRnr1zDs9MduuEY+nGAoNLK8OHDlZeX12NDDAJA3DKkZcnr9XIhQFjphrAl7YlIeyKW1oQsqc6U9klSk05Pc+iScW6Ny3b26jlNSzY00TL0ki82BLzgM/XDsKVkT/vljB210ZiQIkkl2U5FzK6f37u7I7puU9h23/E8XmPpheUh3TzJo2OGUWQEQaVvLoLLJbfbTVAB0CtBxeXiVy9wpLzoM/XiipCuLXbp3PFuOXrxb/uJeQ7boCJJ22uimpbf/rO/pjL29QtTDGUmOlTh71pSeX1Hk67b2tSl1zZa0rfXh3WfU5pZwO8u9C4aHyp23HYA4HcOBvinbMhfgd/ujOiva8Iye/F5m5QdvyC/uiragd8N0svlsdstyO96QNhYGelySDnU9evCqgrwuQJBBQAAdCek0EBAkvTn/VE9tamp145XmOrQVK/9xX+5wlR7mWm/32xuynaYKdldK641Nln6/fr47/8L2Q79++gEvbUwUW8uTNQjc7w6NU4fn0pTemZbiA8VehV1eAAADCaDOKTcWFSlPG9YkhSxHLIcifJFk/VahUtvxfm2/3e7IyrJcmpKXsf7rNw5yaO5w7tWRDo9z6G1u2NrRTaFLZU1mG129t9kU+sy3m2oKK1r/W1e2N6ktSH76/KlXKe+McMr5yGfl3FZTt14lENNy4Na0hD7unvLTJ091lROkuOIXkPgIGpUAADAgOMyTHkU0MjEOn1/cljfKoxfmP/dhrBC0d5ptjQ9J37hfEt1282/3q2IXX9WvlOOLoTPxiZLf94TsV2X7pC+OMnTKqQc5HUZ+up4T9z9ri2P8uEDQQUAAKAtlmUpEA6rpqFei4Y36px0+xL9prCld3ZHeuWcRmc6FG/6kfcr4xfyA02WnqmJ7Sw/I6drRbWVZRHVxOl7f2mBU6ne+OlnXLZTY9z2698sj/DBA0EFAAB0haGh1EnlYFiprm/Q2cPj98f4z+6IeqNfvdtp6IIc+9qdp2tMheKU87dXR3V4jEkxpDFZXWv29c7++COEzcptu0mWw5BOzLAvIr5UZ6mJShUQVAAAQBeK7hpqo34dDCuOSJ1OSbF/7x8GLe2rN3vlfI7KtQ8XYUvaUWufVFbZ1LZckOOU19n50Bk1pVfq4qeJYWntF/+GJ9sfNyqputHkMUOvoJcTAAAYFGGlsalJk5KCeq0h0XabPfVRFaUd+e9oJ7Qx2eT6SlMTc1ovMy3phYrYwv/RuV0713K/qbo4WSLRkNK97YefVI+h8W5D+R4p220ow20ozS2luIwu9ZkBCCoAAGBIh5U8d0CSfVDZ6+9YTdN3NoSlDeF2txvukh4/OSlmeZrX0OlpDr1oM/nja5VRXXDYstL6qLY1xZ5bSXbXimm1wfjvc0aiQx2ZA3NBsVsLit1dvhfdvYaARNMvAAAwiCQ64zd5qgn1XpO4E+IMh/xBo6XKQOsAs8FmNvrTUh1KT+ha1UVjU/z3mcFX1CCoAAAA9D6v04zbXMTfiwNWTc6J3/xr62HDFL9jMyzxiXnOLh870MZQzIlOPiMgqAAAAPSJeHnEafRejUpBSvxZ6lccUoNSH7Jsm4i1FXS6g+4lIKgAAIC+YQ3ttx824xfFU1zN/Vh6g2E0z1Jv55mqaMsQv1ttJoGc7DFUlNr1IlpSGyOFBRlaGAMILRUBACCsDBp14fgdwB1Wk0JNDnndbXcSv3OSR3OHd7+IND3HJe2OTQY1prTbF9WYTKdW2gxLfEa+s0Md3uNJaOPtBcze+XD01DXE0EaNCgAAGDT2BT1x1yWqUdUNDQo1RXoly43OdCgzTklrY1VUUVN61qZ/yvRuNvtK88RPOVuDFh8SDBhEXQAAMGh84E+Iuy7b06iqekOSoYiRfMTPxe00dH6OQ38tj+2D8mZFVJOzoyo9LKekO5oDTnfkpzjkMZonmDzcnogUjEgJ7ZQAQxHps28GNNxtKMdtKMMtpbsNpbgNLRzhUl4K33WDoAIAADrJGKI9pvc2JmhV2L5oM90TUZIzomCToar6epkuQ5LniJ/TUbku/bU8dj6RNxosTdgT2+3/ghynPM7u3UC309CpaYaer7OvPdnfYKo4o+2gsa8+qvKoVB61pMNqYRYVU3xE7yAOAwAwqFLK0HzbTaZDz1WlxV2/ID0gSbJkKRiJqMbf2CvnNb6NWervK4vaBJueGe3ruNz4YWJrTfvjNK+ptJ/aPschZSUydhgIKgAAAO0Kmw49W56ptU32hfxRTlNjkwMtP1uWpVC0d4a/OjhLfUdNyO6ZoHJMoUvxuqr8Y3dUETP+axubLD24p8l23efznXIYBBUQVAAAAGxFLEO+JrfW+FJ0995cvdEYvxnXRbl1chw2h0pvDVMsxZ+l/nBnpDmU5u2ZEJCeYOiyfPvjrg1ZemJTWHaXwLKkf20KaVecSpd5hTT7Qu/h0wYAAAaEX5Rmd/o1F6cHVJQY7NRrvrMhLG0Id+o1Z6c7dMMx9h35J+c4pa1NPRZoOuqC8R49X9kom64wumVPRPuDls4Z7VZhqiGHYaisIaqntkX0UJxmX2enOzQuy9kn1xAEFQAAgEHjgpRGHZvl6/PzKEhxaJrX0JpQ27U4k3p4NvqMBEM3TPToirX2geHhyqgeruxYEziPIX1loke0+kJvoukXAAAYVFySvpzh18m5tTL6weyXhiGdnt92CJnmNVRwBIb8nVXo0q/Hubu9n7uneVSURrERBBUAAIAuWZQU1k3DKzQn09evzmtaO53kT+/mbPRtOWW0W3dO8qgrg3UVOaW/TPdoRj6NcND7+NQBADDoGBrs4xS7JRU4TeU4TeW5oxqbGNaIxKBSXJF+eb4HZ6mviTPa1vQebvZ1uLnDXXo8y6l/bQ7r7xXtN/dySvpagVPnj3MrM5HvtUFQAQAAPZVTBqgMT5PuGr3viB8nyxOOexzDMOR2OpWZnKyc1FQleT0yjO5PwvjSKUnd2kduskPLTu36PrKTDF0506sLA5bWV0a1qiqq3Y2mtoUsRSxplNehCcmGpmc5NSXHqayktt9zfkr3zgcgqAAAAHSCZVlqikZV09AgWZZy0tOU5Ol+WOkvspMMnTDSpRNGUgxE/0ZdHgAAg6+ofeAfuh1W/H5V+uoVCIVlWlxToDcRpQEAAOLEvZaaFVlQKEBzAAAgAElEQVTKVqqSvF5mZgcIKgAAAP0jrFQ3+Jt/SBNhBSCoAAAA9J+wUuP3Ny8grAAEFfQ9X2NExz63t0Pb5jkNFbgdGp/i1OQMj2YWJmlifmKHxoXvzHHiefP0IuWkuLu8b68hZToNFbodGpPs1Mwcj44enqyRmQndOq+d1UFtKg/po8qgPvZHtCtoqj5qaWyCQ0WJTs3I8mpiXoIm5CbI4+p+t7GePt5He/26aGllj32m7piRoVMnpPNwAYjr9Zdf0a9v+GmrZdf87AZ96qwzWy179cWX9duf3tRq2Q9u/IlOP+fsVsuee+Ip3f6b333ye+j++zRl+vRW2yx59TX98robWn7+5/NPKzcvr+XnHdu26+tfWCxJemPp/1QyenSrsPK3vz+k71z9g5btX3n5ec095mjb99fU1KQPV6zU8uUfaNfu3UpKTNK0aVN04gnzlXfIMR9/4kld9tVvtHu9lrz2snZ8/HHMtvfec5cuvujCVsse+/fj+trl32y17J67b9cliy/u1PF27tqtL132tZZlG9d9pKKiwpafN2zYqLnzTpQkbdu8TmMnTOnQvf9oxfsaPXoUDwEIKuhZ5VFL5dGoVgejerwyLG1t0FmZbl1zbI5yUzz9/vxDllQWsVQWiWpl44H3sLFB3xyeoK/MyVGyp3Nj3G/a36gH19Xoyaom++vlj0r+A8fZXK/JXoeumpyuE8akyuXo/Ld0vX08AOhN/3vtdZ125hktI29ZlqUlr7za7uui0aheePqZVstWr1gVE1QO9+zjT+or37QvtNcFGlXpq1fOgZoVMxrVgw8/0mqbpUvftQ0q1TU1uv6Gn+mRfzwasy4nJ1v/+ufDOvqoOT1yzZ5+5lld9IXPt7pmTz719BG5P3994O+64fpr+aCiRzHqF46o52qadOmrZapoCA/Y9/DHPUHd/m6lzA4O9mKalp5cW6Pz3yyPGxrsrA+Zumpljf7f/8rka+z4hGW9fTwAA8AgGpxqeHGxJOn9t5eqsqKiZXlFebnee+vtVtvY2bt7jzav39Bq2ZP/ekzhUKjN4/7jr3/Tlk2bbNd9MhqYT4FQSNu279AHH6xotc19f75fwWCw1bJwOBw3pEhSZWWVzjnvs9q1e3e3rtnEkgmSpBdf+q/27Sv75FqUlur5F15qtU1PufkPt2r16jU8eyCoYGDZ2WTptmVVA/o9PFIe1Jbyxg5t+7cVVbp+g6/Lx/pPZVjfeb1MDaFovzwegIFg8MxMf+b557b8/8fbtrf8/7bNWyRJWTnZOuO8c+K+fuO6dZKk1PQ0FY8ZI0mqrqzSro93tnvsfzzwoCJNTW2ElYAqfD4tXfa+pOYakSlTJkmSSkv3afOWra1e89bb77SElIklE/TOW2+ouqJU27ds0He+faUkye/365+PPhZzvF/94ib5aspt/82ePavVtpdeeknL/6/f8ElIW7t2vSSpqKhQl35xcZvvvTPHO+jW2+5UOM71OvT1Tz7+r5bl3/vut1utGz16FI8vWtD0C11y7ZgUXTonW5JkWVIoYmpvbVhPbvLpr/tiC/RPVYd1VW1IwzK8XT7OkXoPliWZlqVgxNT2ypBuWF6lLWEzZvstlSGV5Ce2uc83t/n0hx1+23XfHJ6gsyakqyjdI6fDUI2/Sct3B3TzRp/Ko62//nw/ENUd71XquhPy5GijWVZvHG/GsGSt/1yy7THWlwX02bcqYpbfNztTJ4xN40EB0G1Tpk9r+f+Vyz/Q0ccdK0la9s5SSdJ5n/+cUtNSbV9rmqZePVCDcO7nPqvklBTdd/udzb+/1qzVOJtahXETS+RvaNC+PXv11muv68OzztDc+cfHDSvV9Q3657+ag8VXv/Jlpaen6yfXN/evWb78A02fNrVl+0MDyA3XX6dpU6e0BJyrvnmF7rzrnuaQ8Ovf6apvXtHla3Zok7O33npHi05ZKEl65UBTucu/9lVlZPRMX8HZs2bK5/Np67bteuKpp3XxxRfqtFMX8cFFj6BGBd1mGFKC26GxuQn63rxcnZrutt1ub11Tvz1/p8NQssepaUVJumZahu12gajZ5n784ahuWl1ru+7Wqen69nH5Gp2dIK/LIZfDUG6qR2dMztBDJ+eryBUbRh4pD2rV3kC/OR4A9IVhI4Zr0rTmAv1jDz2iQCAgX12dnnv8SUnS9Nkz4762rHSfVry/XJI0dcZ0TTxQ2yFJLzz9jKKR2GavKakpuuLq77T8/Mfb71JDfX3cY+zevUfvvfNu8xc7s2Zq1qxPzuehh/+hyIFj1NfX67F/P96ybtasGa32U1hYoEu/eLGu+cH3dO89d7W87qDrb7xJaZl5rf5NnDLD9pzGjB7dElZuu+MuNTQ0qLq6Rn++/wFJ0rx5x7Z73Tt6vPT0NP3yFzd9EsBuvEl1dXV8cEFQQf/jdBg6dViS7br68MBoWpSTZF/RmJfYdmf6t7bXqywS2zD8skKvPj0pI+7rRmR69ctZmbbr/rKuVvEmQu7t4wFAn/xdcTp12iGjfe3+eKd2HNIEbNSB5lx2Nh/S7Kl49CiNOKQvy9aNm1S6J3ZEyFAwqGOOO1bHnXSCJGnPzp167aX/dugY2YUFKhoxvOXnFStXaceOjyVJDQ2ta7/TUmNrne++83bdeMN1uviiC7tV4+F0OluN9rVly1Zt2Lix5edJE0t67P4EAo06ZeHJOuvMMyRJGzdt1r//8wQfXBBU0D8leuybKnkdA+PjttsX28HSa0jTi5LafN3zO+2bYH1mYka7xzx6ZIpm2QShJfURlfnC/eJ4ANBXJk35ZGjbTes36KMPmzuuX3DRhUpJtW/2ZVmWlrz6miRp+pzZysnLU0Zmphac9kmzpE0bNti+1u3x6JKvXNby8103/0Efb9/e7jG8KakyXW6de0ifmZWrVklqHn2sVQHsQDPbd99dFlNzkZaZpy2H9W/prDlzZrcKTG8faCr3rSuvUHp6zw4R7/V6dc0Prm75+fs//LE2bNzEBxcEFfQ/pQ32TbzyUjrfJeq32xs0+d872/33/s6GLp+vZUlR01J9MKL3dzboD+tiO6b/Zkq6spLdcffhC0b0mi+2CcFot0Ojs9ufh8XpMHTuSPsgtKUy2OfHA4C+NKK4WKnpzTUQLzz9jJ480CfkYH8VOxXl5Xr79SWSpJNPPaVliN5j589v2eb1/74iK0418oRJE3XhIZ3S/3jr7e0eI2JZqgsENHfevJZtHn/iKVmWpaSk1n0c63ydGwTFrnP7xnUfxd1+/Lixyslp7uP50MP/0H1/+oskaeHCBUfkeDNnztD3D2ky95PD5sEBCCroc9X+Jj3wcWw/hyKXoVHZ3n51rgdD0JT/7NS0x3dp7rN79eX3q7T7kOZUeU5Dd8/IaLMplSRVNtgP77sw16OOTlw8NtN+rpndNn17evt4AAaWwTPmVzNvglcXfKG5KdPWjZtUX9dcyB8zflzc12w55Bv9O377ey06+jgtOvq4VhNEvv/2UpWX7be/hoahcz//2U/+vlVWdegYC+bM1U9+9Ml8Ii++9F/t2bNXmZmZrTq5f3igVui44+a2BIHzzj27x65ZYmKirrj865Kaa1QqD5z/1ClTjsxnzjD0ta99UgtVWrqPBxEEFfS9qGnJ1xjRyj0N+s4b+237TfxoUnqPzLre287O92pMtrfdfhv+sH1H+9yEjtcipcaZULLWZt+9fTwA6GvTZ7XuNH/SolOUnZMTd/t3lrzZof1u3bQ57rq8/Hz94MafdPsYqz5a3VyQ/+onBfkfX3eD3n13mRobGxUIBPTc8y/qqaef7dFrdnin+c9ccJ4KCvKP2D0aPmyY7rn7dj6sIKigbx3aJGva47t07HN7tfjdKq1ojO0wf3VxohaVpA/I93l/aVBnvL5fP1uyT7WB+JMiBpvsC/dJro5/p+mJs63PZhCC3j4egAHGGHxvadTYsa1+PuGUk+NuW11Vpf8+93yH9rv0zbfaXH/SKadonE3n884c45nnX1DUNPXpT52mo45q7jtSWrpPnzrjbOUXFatg2ChdfMmX2tyH3ShcB/+tWLHS9jWTJ01s9fM5Z5/V4evdleNJ0rnnnqPZs2byDIKggv7NJekXE1P01aNy5ejiH81rx6Ro/eeK2/13THHKEX0v/6kM62uv7lNdnBncE9z2j1JjpOO1E+GofbVNmk3NR28fDwD6WnpGuk4/pJP6hDZGrjo4GaQk/er2W/Tq8ndb/fvd3Xe0rH/52edUU10dd19JyUm6/NtXdesY/3r0Me3YvVspqSn6y5/+2KoJ2KFuvP46PfzgAz12zbKysnTZl77Y8vOMGdOO+H1KTUnRTT+7gQ8seqwsCRwRDx+f2+5IWX3p8EkrTctSY5OpXTUh3be6Vq8c1ldjfcjUE+tqddlRsU0Nkj32waEy2PHaifo4M8Nn2Oy7t48HAP3BsfOP14tPPaMpM6aroLAo7nbvvf2OJCmvoEDTbL7dnzx9mgqHD9O+A8MTb29nhK0Zc2br1DNP1yvPv9jlY7z34Url5OaquLhYTz7+Ly199z2tWLlKFeUVGjZsmE444XjNmT1L23fs6NFr9qlPnaoH/v6Q5h03V8UjR/bKfZp//DwtvvgLeuQfj/KhRbcYEyeUDPlZE15f8oYKCgpaRgTBJ3yNER373N4uvfYLuV5df2K+nB2oTol3nJ6Ymb4r+672N2nBC6U6vP6kwGXolXNHxLyn+mBEc5+NPUaJ16EnzxnRofP8z5pq/XRj7KRi987O1ImHzfLe28eLh5npO8+yLJWVlWnhgpO5GJLmHjtXv7v5Zi5ENz9TgUBAy5Yt0/3336/yinItWHSyjj/5ZGXn5clw8OVDf+ByOJSalKjctDSlJiTIyX0ZlEzT1Nq16/XIPx/Vu++9r8LCQi1evFjz589XQkICF6iTeErQJYc2yXp2QZ5t1dyjFSH9Z3XNgHx/WcluzUyKbQJVFrHkt+nDkZrg0qnpscMXbwqZ2tGB4X6jpqWndtrPCj8+x9vnxwMAdE/ENOULNKqizqf6xkZFTQYuAQgqOOLG5ibqlhn2neV/vqVey3c1DMj3FW/wq3g1RGcU2zdze2xDXbujhr2/s8F2IIKT01wqSPP2i+MBALonapryNTaqwkdYAQgq6DWLxmfo8mGJtuu+u7xae2tDA+r9fFwV1Gqb/h7FbkNJbvvO5ieMTlWRzUhafy8L6sUNtXGPtasmqBtX2dc8fXVyRtx5UXr7eACAngorQVX46gkrAEEFvcEwpMuPytY8m9nna01L179ToYZQ/x721jQt1TVGtHRHvb73ToXtNotHJsctyCd5nLppeqbtuh+uq9OdS8u1vTKoUMRU1LRU0RDWixtrtfiNcpXazD2zOC9BM4fFH4ygt48HAOjJsELNCtAeRv1Cj0nyOPXz43J0wWv7VW+2Lgi/H4jq7mUVumZ+xzrXH/Tb7Q367faONR178/Qi5aS4j8i+peZZ6s8oabuD+PyxqfpRbUg3b/fHrLt3b6Pu3dvYoWMdk+TUd4/NkaOda9XbxwMwUAy2uekHb1ixJFmS0hIT6WAPHIYnAj1qWIZXt8+2/5b/wf0hPbO+dkC+r1SHoXvm5Sgruf0gdOmsbP1qUmqXj3VBtkd3LCxQirdj85n09vEA9H8HC7/o72HFUv2BmhVfIKBIlAl3gUNRo4Ied9zoVF1TFdLvd8R+y3/9Bp9GZ3g0c3jygHk/52Z59K05WRqW0bFO5g6HofOnZmlybqIeWlerJ6rCHXrdJK9DV05M04lj0+R2dvyb0N4+HgCgp8NKULI+qVlxOfniCCCo4IhZPCtLa2vCerG2KWbd1e9X6dFUtwrSPf3uvItchgrcDpWkuDQp06PZw5I0OjuhSx3MS/IT9cv8RH29OqhNFSGtKg/qY39EO4OmfKalsV6HhiU6ND3Lq8l5iSrJS5DH1fVKzt4+HgCgp8KKqfpgUNaBurC0xCTCCkBQQXvSEl1a/7niTr/O43TollOLdMsRPk5f77sjirMSVJyVoNNK0gfd8SYXJPXptQWAwRZWmhkHwgpfJoGgAgAAgD5mmpbqgyFJPlmWlJ5EMzAQVAAAANAvwoqp+mBIluWTZCk9iWZgIKgAAIBBwpDB4MQDPKw0hEKSr7mDfQZhBQQVAAAA9LewIktKT06Sm7ACggoAAAD6RVgJBmVZzbPiEFZAUAEAAED/CCuWJX8oJPl8smQpIzmZsAKCCgAAAPpPWLF8kiEpPTlZLqeTfkggqAAAAKB/hJXygx3sCSsgqAAAAKA/sA6EFcPX/DNhBQQVAAAw0Iq0XIJBHlYsn0VYAUEFAAAA/UdzM7Cw5GuuWkk/0MGesAKCCgAA6LcorA4NVktYqW+ZFNLjolgHggoAAOivBdjmUqwsy5LVElxoCjZow8qBeVYs01RmcorcLoYu7kumacm0zANz3/DcEVQAAMAhhVepvr5BtTU1crpdMhwOLsogT6a1hlRb41VuappSvF4ZVKv1mahpqqKiUn6/XxY5haACAAAOKbeapnbt3KXE5JVKy8yQwyCoDAWGw1Cyx6Nkj1cOgkqfMS1Lu3bt1p49pTJNkwtCUIGvMaJjn9vboW3znIYK3A6NT3FqcoZHMwuTNDE/sUPfvnTmOPG8eXqRclLcHd5+V3VImyobtao8pI/9Ee0KmqqPWhqb4FBRolMzsryamJegCXkJ8jg7/sf4vY/r9ZXl1THLH5qbrTkjU+K+bk9tSKe9Uhaz/OcTUvW5GVkxy2sDEc17vvPXbOX5I+R1OQblve7IvjMchorchvI8DpWkuTUq3a1JuQkak5MgF3+BgXYLSmV7S1VbXS23xyODr9eHSEJVc8HYsqhR6cvbYEnBYFCRSEQOajMJKuic8qil8mhUq4NRPV4ZlrY26KxMt645Nke5KZ5+c56b9zfqofW1zedo9z78Ucl/4D1srtfUBIeunJim+WPTKMgOsHttp9a0VBuytD5kakl9RNrbKMmn0W6Hrp6cqhPHpNkGOQCfdKYP+ANSg59W8kAvczgcfEFAUEFPea6mSWteLdODiwr6vABrmpae3VCr69b7OvW6tUFTV66q1ef2BPSD43KVlsBHu7/f667Y0WTqux/VacF2v248LkeF6V5uKnAYy7JkGAbf5gJ9/zByDQgq6Ak7myzdtqxKvz6lsE/P48GVVbp5u7/Lr/93ZVh7Xi/TnacUKtnLyCf9+V53x5L6iHa8sV9/PilfwzMJKxjaDn5za1qW5HDI4T7Y5JJvdIG+ezCbn00GsyCoII5rx6To0jnZLaE+FDG1tzasJzf59Nd9jTHbP1Ud1lW1IQ3L8Hb5ON3x9rb6uCHlm8MTdNaEdBWle+R0GKrxN2n57oBu3uhTebT1Nxbv+qO6c1mFfjw/X44+bgaWkeTS+s8Vt/wcr2/MP+flaMaw5CFzr+18rzhZXz8mR5YlRS1LjeGo9tU16X87/bptp982cP3onQr96dRCpRBKMUQDinlgeNrSqiqV1vtkFeQpKT2NiwP0k7BipaSqLtIkfzgkb0KCHGLQYoIKbP6gSQluh8bmJuh72V7tfnWfXqlritlub11TpwuvPSEQjuqm1TW2626dmq5PT8potSw31aMzJns0rTBRly3Zr9JI68f+of0hfbrUr1nDU7jX/exed+T8XYah1ASXUhNcmpCfqPkjk3TtsiptCbceQWVVY1T/XlOjy47K4SHHkBKKRlVb71Ntfb32VlZq8949WldWqqacbLkZaQjoLzlFQZdL6ysrlLZls8YUFCk7I0PpyckEFoIK4nE6DJ06LEmv1NXFrKsPR/vknN7aUR8TNiTpskJvTEg51IhMr345K9O2luKv6+p057CUIT36SX+8110xqSBJt8xz6Jwl+2PW/X6HX2dNTBuQfW6AzrAk+UNB7a+uVnldrXbsK9PuinLtrqlRZWNAwUhEcjokmpoA/UajYWhNRbnKA36Nzc3ThKJhGj9smApzcpWckEADTYIK7CR67B8Nbx/9gXthZ8B2+WcmZrT72qNHpmjW2jqtbGxd8H7NF9F+X1gF6R7udT+61101LjdB145J0W+3N8SsW7YzoLOmEFQwOMNJJBpVnd+v8ppq7ams1LpdO7W7qlKVgYD8TU1qOlCDQoEH6I8PsaVgJKKddXXa39CgjWX7NHb3Ls0YNVpji4qUn52tZC+BhaCCVkobmmyX56V0/iPx2+0NtoXHw/3tmGwdUxzbFKs+GLFtmjTa7dDo7IR29+t0GDp3ZJJWbqqPWbelMjjkg0p/utfddfzIJMnm+G/uC+isKRk82Bg04cSyTDU0BlXlq1NFXa127t+vDXv3aEdVlXyhkCKmKetAOKGAA/RvB5/RUDSq0oYGVQQC2ly+X5MKCjVj9GiNzC9QflaWUhISRX0oQWXIq/Y36YGPY2swilyGRmX3fp+FioaI7fKFuZ4ON9sam2kfRnbXN3Gv+9G97q5R2QlySTr8E/N6bZOipiUnc+hgADMtS5FoVDX+BpVVVqq0skrb9u/TjooK7av3KRCJyLSslkIPn3ZgYIaWiGlqv9+v6h3btWl/mcbn5WtKcbHGFBZpWFa2krxehhcnqAwtUdOSPxTVtqqgbllVqzKb/iA/mpQuTx9MoucP23f8zO3EXCipHvtRn2qCUe51P7rX3eV0GJqc4NTqw+5rwGoekCGV+XMwAMNJ1DQVikRUVVurvZUV2r6/TOt271ZpXZ38TWE1UXsCDNrAUnaghmX9vlKV5BdoRvFojRs+TAXZOUpwu+V0OIb0c89f9UGso810JOnq4kQtKknvk/MMNtkHlSRXxx9NT5xtfWGTe92P7nVPKEowtDoYu7wpyvgpGFiCoZBq/H5V1NSorKZGW0v3am3pHpXV+2San9ScOERCAQYtS7JMUzXRiN7bsV3rS0s1a8QITSkepZG5uSrMyVVaUhJBBUP3A/CziSk6b0qWutpqprtza3jd9t/sN0Y6HjLCcQqpSS6qTvvTve4JZSH7e+12UpLDwLJm3Tpt3btXO0r36uOKCtUFmucL8hJMgCErZPn0Xnm5Nm/cpInDh+uoKVM0b85RBBUMTQ8fn6vpRX2b1JPd9n+RKzvRbKs+ZL9tlpeg0p/udXdFTUsbbD4XGQ5DSR4mfcTA8s7bb2vZig8VCIZaak3IJwAsSfssSzWbN8sTDBFUMHQ9tdmnKQWJfdoJOSfFbbv8zaqwvtfBfeyoDdsuL86w72TviNNL32yn9ZAVZ71rAHyb3x/udXftqgnJrkJlUZabjvQYcAzLkq+8QoFAgIsBIEZycrLCweCQvgYElUHs0GY62yoadf6S8pjRkh6tCKlkdY0unJnVZ+eZnujS8SkuvXPY6F+bQqZ2VAY1OqftIYqjpqWn4szDMjbOyFZJHvualoZ2+rT440ySmOJxcK97wXu77PvhnFiUxAOPAWfYsGFKSk5W4xAviACw53A6h/zoX7SLGSLG5ibqlhn2Hah/vqVey3c19On5nTsy2Xb5Yxvq4tZiHPT+zgataIwNEAtSXRqWYR9UMhPtmwmtr2q7wPBxjX3NTU6Sk3t9hO2uCek3W/0xy1Mdho6J8/kB+rPx48crKytLhkFtIIBYXq9XeXl5BBUMDYvGZ+jyYYm26767vFp7a0N9dm4njU1Rqk3Tnb+XBfXihtq4r9tVE9SNq2ps1102Of7IVoXpXo23qQV5YE+j9vvsw0ggHNWDW+0L+WM7MDEl97rrdlQGdfVbsbVEknRtSYrSEqkcxsBTXFyskpISeb1eLgaA1gV0h0P5+fkqKSkhqGBoMAzp8qOyNc9mRvJa09L171SoIdQ3846kJrj06+n2weKH6+p059Jyba8MKhQxFTUtVTSE9eLGWi1+o1ylNvOEfCbHoznD43/L7jCkr46NnTk9YEnfe7NcK3b71RCKyrSah0/euD+gG/+3X6tsam6+MSyx3xWU+/O97oioaakhFNW2iqAe+rBSFyzZrw2h2GZ5p6S5dOZEZqTHwJSdna3Zs2crLy+PWhUArSQlJWnmzJkaMWLEkL4OfA051D74Hqd+flyOLnhtv+oP6zn+fiCqu5dV6Jr5+Z3qmNyZOTzePL0obuf5hePSdUVFSPfubYxZd+/eRtvldqYnOPWDublytPMeFk1I06yP/Vp5WPhY1RjVJe9VduhYeU5DF02LX1CuDUQ07/m97e7noqWVkj455srzR8jbzaGV+/O9tnPbTr9u2+nv8PbTE5y6aX7egJy4EpCaO8pOnjxZM2bMUEVFhRobG7koAOR0OjVx4kQdffTRSk1NHdLXgr/wQ9CwDK9un51pu+7B/SE9s762T87LMKSrjs3VtWNSuryPU9JcumdhvjKS2s/gSR6nbjkhTyVdHMI4w2HovuNzlZfq4V73srMy3bpnYb6yk9080Biw3G63RowYoRNPPFHjx4+nVgVA89/uYcO0YMECjRo1Si7X0K5TIKgMUceNTtU1o+2bRl2/wadVe/x9cl5Oh6FL52TrPyfkalFaxx/OsR6Hbp2WrlsXFSmrE4XXgnSPHjytUN8akdip87wo16unTitQSX4i97oXTU1w6N5Zmfr1wsJO3WegPzIMQ6mpqZo5c6bOPPNMwgowxJmmqby8PC1atEizZs1SSkrKkP+dQNOvIWzxrCytrQnrxdqmmHVXv1+lR1PdKkjvm9qCyQVJuj0/SbtrQvqoNKANNWFt8DVpRSAa06H6vCyPblqQL4+za7k7NcGlK4/N0xemNemjfY3aWBXS2tqwSkOmdodNFbodKvA4NCXdrUnZHk0vSFJhuod7fQRlOAzluw0Vehwan+rSqHS3puQlakxOglzMl4JBxOl0Kjc3VyeccIKi0aheeuklrVmzRqZpElqAIcKyLFmWpdGjR+uUU07R/PnzlZOTI6eTiYyNiRNKrKF+EV5f8oYKCgr4ozAAPPBBpX6/o3UNwGSvQ4+eNZwCLIyzvecAABHqSURBVAbMH6SysjItXHAyF0PS3GPn6nc33zwk3/uhBZGmpiaVlpZqxYoVWrJkiZYuXSq/v/l3HX+bgMH9N8Hj8WjatGk6+eSTNXPmTOXl5cntptWARI0KBpjR6bEP7vqQqb99WKlzJ6UrK8mtqGlpa2VQ/1hfp4snp2tyAZMBAujf3G538wSQSUkqKCjQuHHj9OGHH+rjjz9WbW2tIpGILMviQgGDhNPpVGpqqoYNG6aZM2dq2rRpGj9+vNLT04f8JI8EFQxY04uS5P2oVqHD/l7f+nFAt34cOzv9xVwyAP1UJBKRabYedjs9PV1Tp05Vbm6uSkpKtH37du3fv1+hUIigAgwShmHI5XIpOztbI0aM0KhRo5STkyOPx0MNKkEFA1lWsls3TUrTdet9XAwAA1ogEIhbKMnKylJycrJGjhypQCCgaDTKBQMGWVhJSEhQamqqvF4vAYWggsHi7MmZMi1L12+o52IAGLDC4XCb6x0OhzIzM5WZmcnFAkBQAQYChyGdPzVL80amaOkuvz4ob9T6hqi2hUx5DGmEx6EpKS5Ny/KoIJXOaAAAAAQVoBflp3l0/lSPzhffNgIAAAw2DCsAAAAAgKACAAAAAAQVAAAAAAQVAAAAACCoAAAAACCoAAAAAABBBQAAAABBBQAAAAAIKgAAAABAUAEAAMD/b+/+g6yqCz6Of5bFFoSW2SIW0iZAWCERxWcSRcj8BYlmPwkt5Dc6j5EoYqZPkImDgooWmhlgqflM9jxl0zQQKBOKv8Yex5/JojBZboos1kgELOyP5w/zuheWn4KCvl4zzOy995yz537Pcua87zn3XhAqAAAAQgUAABAqAAAAQgUAABAqAAAAQgUAABAqAAAAQgUAAECoAAAAQgUAAECoAAAAQgUAAECoAAAAQgUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAAChshMlJSUGAbDPAYD9SGtDkNTX12fLli0OHoB9rqmpKfX19QYCAITKztXU1KSuri4lESrAPg6VNKW2ttZAAIBQ2bkxo0YbBAAA2I94jwoAACBUAAAAhAoAACBUAAAAhAoAACBUAAAAhAoAAPCB43tUAOB9avr06Vn96qsGAvYjnbt0ydSpUw2EUAGAD67XVr+WPz33JwMB+5GSEhc07SojBQAACBUAAAChAgAACBUAAAChAgAACBUAAAChAgAACBUAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAACECgAAIFQAAN49U6dNy/IV1YV/c+fNS5JMOP+8ovuvu+H6/W4d99T+9Nx2xeL77yus61PPPO2Pll3S2hAAwAfP3HnzMnDQwBYf27BhQ/6j3zEGCXhPOaMCAADsd5xRAQAOaNOvuirTr7rKOoJQAQAOdBPGjy/83LlLl/xh6R8MCiBUAIADwyGHHpJLv/3tdOvWLRUVFWnXrl3atGmThoaGrF+/Pn/729+yZMmS/PhHt74dQeefl8mTJxdu/+53v8uSJUsyevTo9OjRI23atMm6devyyCOP5Dvfviz19fV7fb5LL5myw+d1ZN8jM//22/PhD384SdLU1JRbbrklmzdv3mZZ9y2+L2PHjknPqqq0bds2o0aOyh8ffzxH9OmT884/L0cccUQ6duyYgw46KHV1dVm9enWWPbgs18yYscMxufSSKXv8nFvyuaGn73S+vbU9tzcmw885O8OHD0/Xrl1TVlaWf/7zn3nmmWfSpk2bPf4b7FlVlQnnTUjfvn3TqVOnlJWVZcOGDVm3bl1WVK/Ib37zmyxetChJcuJJn83IkSNTVVWV8vLylJaWZuPGjXnllVeydOnS3HjD7B0+rwceeCCjR4/OYYcdltatW2f16tW55557Mu8nc5Mkl1w6JUOGDEmXLl1SX1+fF198MTNnzswTf/w/OwuhAgC8m7p1754hQ4Zsc3+rVq1SUVGRioqK9OnTJ5/61Kdy4cRvtbiMfv365fTTT09paWnhvoqKipxxxhkpLy/PeeMn7NX5dnrw07p1ZlxzTSFSkmTx4sW5Zc7NmXD+eUXT9unTJ0OGDMlBBx3U7LmX5NxRIzNp0qS0a9euaPq2bdumW7du6datW47ud3SGD/vabq3bvh6rvbE9tzcmU6dNy9nnnJ1Wrd5+C3SHDh0yaNCgPf77GzHy3EyaNCnt27cvur99+/Zp3759Pv7xj6eyc2UWL1qUiy+ZnDFjxhSt11vTVlVVpaqqKoMGDcq4MWPzj3/8Y5fG8NBDD83FF1+csrKyDB48OFVVVUV/R0ceeWRmz56doZ87Pf/617/sMPYyb6YHAN6xU089NScMbPlTxA455JCig7/mBgwYkJ7NDv72xnw7c90N16dHjx6F28uXL89FF05qcdquXbtuc+B7WI8emTx58jaRsrW+fftm2pXf261121/Gakfbs6Ux6XvUURl+9vCiSHmnBn5mUKZMmbJNpLTki1/6YsaNG7fNem2td+/euX72Dbs1hq1atcrEiROLIqW5Tp06Zez4cXYCQgUAeLe98cYbWbx4cS677LIMPGFgTj3llFx00UV58sknC9OUlJRkwIABLc5fU1OTmTNn5tRTTskVl1+edevWFR4rLS3NZ078zF6db0dGjRmdwYMHF26vXbs2F1908Xanr66uzrRp03LmGWem9+G90vvwXhk6dGjRpUz3339/RowYkaGnD80dd9yRxsbGwmMnnnjibq3fuzFW73R7tjQmp5x8ctFB/urVqzNjxowMPm1wxowek9ra2t3eVhdccEHKysoKt19//fXcdNNNOfOMM/PVr3w1N910U55//vk0NTVlxLnnFv3+5cuXZ/y48TnzjDNz9913p6GhofBY//798+ljj93m97388suZMWNGTvrsSbn55puLtmOSLFy4MCPPHZmzPn9WnnvuuaLHDj/8cDuKfcClXwDAdj304LIcd2z/nPONr2fIkCEZO3ZsOnTokHbt2uXggw8umvbgdge3uIynnnoqP7v9p0mSe2vuzelDhxZdDlReXr5X59ue9u3bZ+LEiYVX/evq6jL9qun5y0svbXeelStX5n/u+WXRfb179y46uP3WNycWbl8745ocf/zxhVffO3funNatd/1wa1+P1d7Yni2NSfMzNg0NDfnetO/lwQceeHOM/vrXbNq0abf/9nr16lW0zO9feWXuW3xf4b4/Pfdcbrv1x28+/2ZfIrl58+ZcOuXSrFq5Mkly9VXT07Nnzxz77zgpLS3NaYNP2yaenn766dx1x51Jklvm3Jxhw4alsrKy8PjkZkG7YMGC9OnT5+2xOvhgOwuhAgC8mw7v1Suzb5yd7t2773TakpTs0jKbv9qfZJcvF9rT+d4yaNCgolfda2trC2/C3lXduncvOij9xCc+keUrqrc7fatWrXJYs8vMdtfeHqt9sT07d+lSNCZ///vfC5Gypz7ZtWvatm1buL127dqiSNk6kpqfeamtrS1EyltWrFhRCJUkqays3OlZnh2952TNa2uKx6qkxM5CqAAAe1uHDh22+9i1M68tHNQ2NjbmoYceyhNPPJFVq1blqKOOyoQJu/+G9rq6uj1azz2d7y2lpaVpaGgoxMqhhx6a6VdPz9TvTt3lZXzoQx/a7d/b/ID7vR6rfbE9t36vzpYtW975AepWZ6Gampp2GINbb+etNTU27fY6NG116Vdz9Q31dhxCBQDY104YeELxQdi/P8q2U2WnomvvV61alfMnvP2pWM0vgToQrF27NnPmzMm0adMKB7OfP+usLFy4MI88/MguLWNFdXXq6uoKr+DX1tbm5M+etMOPDU6STx/76ff8+e+r7fmXl15KfX19IS4+8pGP5KMdO+b1tWv3eF1XrVxZNM4dO3bMcccfn8cefXSn26SioiKf7Nq16JK+nlU9i+ZZs2aN//gHAG+mB4APkPk/vT1z589L/+P656MdO+arXxuWESNGFE3z1iUx3bsfVnRJS2VlZT7/hbNSUVGRL3/lKznttNMOqOf+2GOP5Ze/uCcPNLssqaysLN+5/PLdWs6LL75Y+PljH/tYfnXvrzNuwvj0PfqolJeX5+h+/fKfF1yQO39+V5Y9/NB+8/z31fasr6/Pq6++Wrjdpk2b/HDOD3PCwIHpWVWVCy+alIqKihbnPfmUU7J8RXXh34LfLyw89sILLxR+bt26da6deW3GTRifbt27p2dVVUaOHpVf/PKe/O+vf5WVzS71Kisry4033ZiTTj4pn+zaNd+54vKiy74aGxuzeNFiO4MDgDMqAPAB0qpVqwwYMCADt/PRs0mydOnSJMmzzzyTjRs3Fi5dKi8vz6xZsw74Mfj+lVemX79+hYPnnj175vIrrij6gsYdxt78+Zk1a1bho3CrqqoyZUrLXzC59XtF3kv7cnsue3BZvv6NrxduH3PMMZk3f947i+r583PdddcVxrmysjJTpkzZZqyff/75/PyuuzL96qsLZ8p69+6dH916a4vLffzxx/PHxx/P0f2OtkPY3/dXhgAAeMvDDz+c62ddl+TNNxMvWLBgu9M2/8jXA8ma19bkzjvvLLpv2NeGpe/RR+3S/L9fsDA/+MEPDrgv+NuX2/OaGTOKzmrsjWUvWvj7zJkzJxs2bNjptPf++t7c8bM7dnoJXnV1ddGndyFUAID9RM3LL6e2tjabNm1KY2NjGhoasn79+lRXV2f27NkZP7b4i+u+e8V/5c477syaNWsK3yuxadOmPPnkk/nvu+8+YMfhxz+6Nc8++2zhdtu2bTN16q6/qX7+3Hk55+xz8tvf/jZ//vOfs379+jQ0NKS+vj7r1q1LTU1Nli5dustnad4t+2p71tfXZ9zYsVmyZEneeOONNDY2ZvPmzampqclPbrstr7zyyh4td+5tP8noUaOyaNGi1NTUZOPGjWlsbMzGjRvz2muvZdmyZZk/780zN9fNmpVJF07Ko48+mrVr12bLli1pbGzM+vXr88ILL2Tu3Ln50he+2OK30rN/KulVdXiTYQDgvdD/uP6Z+T64lGh/NfGbE/Ncs4Nx4L3X58gjc/MtNxuIXeCMCgAAIFQAAACECgAAIFQAAACECgAAIFQAAACECgAAIFQAAACECgAAgFABAACECgAAgFABAACECgAAgFABAACECgAAgFABAACECgAAgFABAAAQKgAAgFABAAB4Z1obAgB4f6rsXJmmpkYDAfvZ/0uECgB8oE2dOtUgAAcsl34BAABCBQAAQKgAAABCBQAAQKgAAABCBQAAQKgAAABCBQAAQKgAAAAIFQAAQKgAAAAIFQAAQKgAAAAIFQAAQKgAAAAIFQAAQKgAAAAIFQAAAKECAAAIFQAAAKECAAAIFQAAAKECAAAIFQAAAKECAAAgVAAAAKECAAAgVAAAAKECAAAgVAAAAKECAAAgVAAAAKECAAAgVAAAAIQKAAAgVAAAAIQKAAAgVAAAAIQKAAAgVAAAAIQKAACAUAEAAIQKAACAUAEAAIQKAACAUAEAAIQKAACAUAEAAIQKAACAUAEAABAqAACAUAEAABAqAACAUAEAABAqAACAUAEAABAqAAAAQgUAABAqAAAAQgUAABAqAAAAQgUAABAqAAAAQgUAABAqAAAAQgUAAECoAAAAQgUAAECoAAAAQgUAAECoAAAAQgUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAECoAAAACBUAAAChAgAACBUAAAChAgAACBUAAAChAgAACBUAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAAChAgAAIFQAAACECgAAIFQAAACECgAAIFQAAACECgAAIFQAAACECgAAgFABAACECgAAgFABAACECgAAgFABAACECgAAgFABAACECgAAgFABAAAQKgAAgFABAAAQKgAAgFABAAAQKgAAgFABAAAQKgAAAEIFAAAQKgAAAEIFAAAQKgAAAEIFAAAQKgAAAEIFAAAQKgAAAEIFAABAqAAAAEIFAABAqAAAAEIFAABAqAAAAEIFAABAqAAAAELFEAAAAEIFAABAqAAAAEIFAABAqAAAAO83/w9sUqgGuLm3/gAAAABJRU5ErkJggg=="



############################################# Variables ########################################################
# Toast Text
$tostTitle 		    = "Companyname IT Support"
$tostHeadline 	    = "A reboot of your system is required!!"
$tostText 		    = "We have installed updates on your system and a reboot is required. You should reboot your system as soon as possible. If now is the right time, perform the reboot now."
$tostMessage 	    = "`nRun reboot now?"
$toastLogoPath	    = "C:\Windows\ImmersiveControlPanel\images\logo.png"
$tostImagePath      = "$env:TEMP\ToastImage.png"
$scripExecutionPath = "C:\Users\Public\Documents"

################################################# Actio #########################################################
$actionScriptCmdReboot = @'
shutdown -r
'@
$actionScriptCmdReboot | out-file "$scripExecutionPath\ActionReboot.cmd" -Force -Encoding ASCII
Create-Action -Action_Name ActionReboot

############################################## Notification #####################################################
# Create png file from Base 64 string
[byte[]]$Bytes = [convert]::FromBase64String($tostImageBase64)
[System.IO.File]::WriteAllBytes($tostImagePath,$Bytes)	


# Create toast notification XML
[xml]$toast = @"
<toast scenario="reminder">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$tostImagePath"/>
		<image placement="appLogoOverride" hint-crop="circle" src="$toastLogoPath"/>
		<text>$tostHeadline</text>
        <text>$tostText</text>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$tostMessage</text>
            </subgroup>
        </group>				
    </binding>
    </visual>
	<actions>
		<action activationType="protocol" arguments="ActionReboot:" content="Reboot Now" />		
	</actions>	
</toast>
"@	


Register-NotificationApp -AppID $tostTitle -AppDisplayName $tostTitle

# Create toast
$load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
$toastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$toastXml.LoadXml($toast.OuterXml)

# Show the Toast
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($tostTitle).Show($toastXml)